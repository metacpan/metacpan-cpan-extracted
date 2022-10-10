package Net::HTTP2::Client;

use strict;
use warnings;

=head1 NAME

Net::HTTP2::Client - HTTP/2 client base class

=head1 SYNOPSIS

    use Net::HTTP2::Client::Mojo;

    Net::HTTP2::Client::Mojo->new()->request(
        GET => 'https://perl.com',
    )->then(
        sub ($response) {
            # Handle the Net::HTTP2::Response
        }
    )->wait();

L<Net::HTTP2::Client::AnyEvent> and L<Net::HTTP2::Client::IOAsync>
exist as well for L<AnyEvent> and L<IO::Async>, respectively.

=head1 DESCRIPTION

This class implements base functionality for an HTTP/2 client in Perl.

=cut

# perl -I ../p5-X-Tiny/lib -MData::Dumper -MAnyEvent -I ../p5-IO-SigGuard/lib -I ../p5-Promise-ES6/lib -Ilib -MNet::HTTP2::Client::Mojo -e'my $h2 = Net::HTTP2::Client::Mojo->new(); $h2->request("GET", "https://google.com")->then( sub { print Dumper shift } )->wait();'

#----------------------------------------------------------------------

use Carp ();
use URI::Split ();

use Net::HTTP2::Constants ();
use Net::HTTP2::Client::ConnectionPool ();

use constant _SIMPLE_REDIRECTS => (
    301, 308,
    302, 307,
);

use constant _FORBIDDEN => ('port');

#----------------------------------------------------------------------

sub new {
    my ($class, %opts) = @_;

    my @bad = grep { defined $opts{$_} } _FORBIDDEN;
    Carp::croak "Forbidden: @bad" if @bad;

    delete @opts{ _FORBIDDEN() };

    return bless {
        host_port_conn => { },
        conn_pool => Net::HTTP2::Client::ConnectionPool->new(
            $class->_CLIENT_IO(),
            \%opts,
        ),
    }, $class;
}

sub _split_uri_auth {
    my $auth = shift;

    if ( $auth =~ m<\A([^:]+):(.+)> ) {
        return ($1, $2);
    }

    return ($auth, Net::HTTP2::Constants::HTTPS_PORT);
}

sub request {
    my ($self, $method, $url, @opts_kv) = @_;

    # Omit the fragment:
    my ($scheme, $auth, $path, $query) = URI::Split::uri_split($url);

    if (!$scheme) {
        Carp::croak "Need absolute URL, not “$url”";
    }

    if ($scheme ne 'https') {
        Carp::croak "https only, not $scheme!";
    }

    my ($host, $port) = _split_uri_auth($auth);

    my $host_port_conn_hr = $self->{'host_port_conn'};

    my $path_and_query = $path;
    if (defined $query && length $query) {
        $path_and_query .= "?$query";
    }

    return _request_recurse(
        $self->{'conn_pool'},
        $method,
        $host,
        $port,
        $path_and_query,
        @opts_kv,
    );
}

sub _request_recurse {
    my ($conn_pool, $method, $host, $port, $path_and_query, @opts_kv) = @_;

    my $conn = $conn_pool->get_connection($host, $port);

    return $conn->request($method, $path_and_query, @opts_kv)->then(
        sub {
            my $resp = shift;

            my $status = $resp->status();
            my $redirect_yn = grep { $_ == $status } _SIMPLE_REDIRECTS;

            if ($status == 303) {
                $redirect_yn = 1;

                $method = 'GET';
                push @opts_kv, body => q<>;
            }

            if ($redirect_yn) {
                my ($new_host, $new_port, $path_and_query) = _consume_location(
                    $resp->headers()->{'location'},
                    $host, $port, $path_and_query,
                );

                $host = $new_host;
                $port = $new_port;

                return _request_recurse( $conn_pool, $method, $host, $port, $path_and_query, @opts_kv );
            }

            return $resp;
        }
    );
}

sub _consume_location {
    my ($location, $host, $port, $old_path) = @_;

    my ($scheme, $auth, $path, $query) = URI::Split::uri_split($location);

    my $path_and_query = $path;
    if (defined $query && length $query) {
        $path_and_query .= "?$query";
    }

    if ($scheme) {
        if ($scheme ne 'https') {
            Carp::croak "Invalid scheme in redirect: $location";
        }

        ($host, $port) = _split_uri_auth($auth);
    }

    if (rindex($path, '/', 0) != 0) {
        $old_path =~ s<(.*)/><$1>;
        substr( $path_and_query, 0, 0, "$old_path/" );
    }

    return ($host, $port, $path_and_query);
}

1;
