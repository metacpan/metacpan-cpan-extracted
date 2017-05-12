package Net::Hadoop::YARN::Roles::Common;
$Net::Hadoop::YARN::Roles::Common::VERSION = '0.202';
use strict;
use warnings;
use 5.10.0;

use Moo::Role;

use Data::Dumper;
use HTTP::Request;
use JSON::XS;
use LWP::UserAgent;
use Regexp::Common qw( net );
use Scalar::Util   qw( blessed );
use Socket;
use URI;
use XML::LibXML::Simple;

has no_http_redirect => (
    is      => 'rw',
    default => sub { 0 },
    lazy    => 1,
);

has _json => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return JSON::XS->new->pretty(1)->canonical(1);
    },
    isa => sub {
        my $json = shift;
        if (   ! blessed $json
            || ! $json->isa('JSON::XS')
            || ! $json->can('decode')
        ) {
            die "Not a JSON object"
        }
    },
);

has debug => (
    is      => 'rw',
    default => sub { $ENV{NET_HADOOP_YARN_DEBUG} || 0 },
    isa     => sub { die 'debug should be an integer' if $_[0] !~ /^[0-9]$/ },
    lazy    => 1,
);

has ua => (
    is      => 'rw',
    default => sub {
        return LWP::UserAgent->new(
                    env_proxy => 0,
                    timeout   => $_[0]->timeout,
                    ( $_[0]->no_http_redirect ? (
                    max_redirect => 0,
                    ):()),
                );
    },
    isa     => sub {
        my $ua = shift;
        if ( ! blessed( $ua ) || ! $ua->isa("LWP::UserAgent") ) {
            die "'ua' isn't a LWP::UserAgent";
        }
    },
    lazy => 1,
);

has timeout => (
    is      => 'rw',
    default => sub {30},
    lazy    => 1,
    isa     => sub {
        if ( $_[0] !~ /^[0-9]+$/ || $_[0] <= 0 ) {
            die "timeout must be an integer"
        }
    },
);

has servers => (
    is  => 'rw',
    isa => sub {
        die "Incorrect server list" if ! _check_servers(@_);
    },
    lazy => 1,
);

has add_host_key => (
    is      => 'rw',
    default => sub { 0 },
    lazy    => 1,
);

has host_key => (
    is  => 'rw',
    default => sub { '__RESTHost' },
    lazy => 1,
);

sub _check_host {
    my $host = shift;
    return !!( eval { inet_aton($host) }
        || $host =~ $RE{net}{IPv4}
        || $host =~ $RE{net}{IPv6} );
}

sub _check_servers {
    for my $server (@{+shift}) {
        my ($host, $port) = split /:/, $server, 2;
        if (   ! _check_host($host)
            || $port !~ /^[0-9]+$/
            || $port < 1
            || $port > 19888
        ) {
            die "server $server bad host (port=$port)";
        }
    }
    return 1;
}

sub _mk_uri {
    my $self = shift;
    my ( $server, $path, $params ) = @_;
    my $uri = $server . "/ws/v1/" . $path;
    $uri =~ s#//+#/#g;
    $uri = URI->new("http://" . $uri);
    if ( $params ) {
        $uri->query_form($params);
    }
    return $uri;
}

# http://hadoop.apache.org/docs/r2.2.0/hadoop-yarn/hadoop-yarn-site/WebServicesIntro.html

sub _get {
    shift->_request( 'GET', @_ );
}

sub _put {
    shift->_request( 'PUT', @_ );
}

sub _post {
    shift->_request( 'POST', @_ );
}

sub _request {
    my $self     = shift;
    my ( $method, $path, $extra, $server ) = @_;

    my $host_key = $self->host_key;
    my @servers  = $server ? ( $server ) : @{ $self->servers };
    my $maxtries = @servers;

    my ($eval_error, $ret, $n);

    # get a copy, don't mess with the global setting
    #
    my @banned_servers;
    my $selected_server;

    TRY: for ( 1 .. $maxtries ) {
        my $redo;

        $n++;

        if ( ! @servers ) {
            $eval_error = sprintf "No servers left in the queue. Banned servers: '%s'",
                                    @banned_servers
                                        ? join( q{', '}, @banned_servers)
                                        : '[none]',
                            ;
            last TRY;
        }

        $selected_server = $servers[0];
        eval {
            $eval_error = undef;

            my $uri = $self->_mk_uri(
                            $selected_server,
                            $path,
                            $method eq 'GET' ? $extra->{params} : (),
                        );

            print STDERR "====> $uri\n" if $self->debug;

            my $req = HTTP::Request->new( uc($method), $uri );
            $req->header( "Accept-Encoding", "gzip" );
            #$req->header( "Accept", "application/json" );
            $req->header( "Accept", "application/xml" );

            my $response = $self->ua->request($req);

            if ( $response->code == 500 ) {
                die "Bad request: $uri";
            }

            # found out the json support is buggy at least in the scheduler
            # info (overwrites child queues instead of making a list), revert
            # to XML (see YARN-2336)

            my $res;
            eval {
                my $content = $response->decoded_content
                                || die 'No response from the server!';

                if ( $content !~ m{ \A ( \s+ )? <[?]xml }xms ) {
                    if ( $content =~ m{
                        \QThis is standby RM. Redirecting to the current active RM\E
                    }xms ) {
                        push @banned_servers, shift @servers;
                        $redo++;
                        die "Hit the standby with $selected_server";
                    }
                    die "Response doesn't look like XML: $content";
                }

                $res = XMLin(
                    $content,
                    KeepRoot   => 0,
                    KeyAttr    => [],
                    ForceArray => [qw(
                        app
                        appAttempt
                        container
                        counterGroup
                        job
                        jobAttempt
                        task
                        taskAttempt
                    )],
                ) || die "Failed to parse XML!";
                1;
            } or do {
                # $self->_json->decode($content)
                my $decode_error = $@ || 'Zombie error';

                # when redirected to the history server, a bug present in hadoop 2.5.1
                # sends to an HTML page, ignoring the Accept-Type header
                my $msg = $response->redirects
                            ? q{server response wasn't valid (possibly buggy redirect to HTML instead of JSON or XML)}
                            : q{server response wasn't valid JSON or XML}
                            ;

                die "$msg - $uri ($n/$maxtries): $decode_error";
            };

            print STDERR Dumper $res if $self->debug;

            if ( $response->is_success ) {
                $ret = $res;
                return 1;
            }

            my $e = $res->{RemoteException};

            die sprintf "%s (%s in %s) for URI: %s",
                            $e->{message}       || $res->{message}       || '[unknown message]',
                            $e->{exception}     || $res->{exception}     || '[unknown exception]',
                            $e->{javaClassName} || $res->{javaClassName} || '[unknown javaClassName]',
                            $uri,
            ;

            1;
        } or do {
            # store the error for later; will be displayed if this is the last
            # iteration. also use the next server in the list in case of retry,
            # or reset the list for the next call (we went a full circle)
            $eval_error = $@ || 'Zombie error';
            redo TRY if $redo;
            push @servers, shift @servers if @servers > 1;
        };

        if ( $ret ) {
            if ( $self->add_host_key ) {
                # mark where we've been
                $ret->{ $host_key } = $selected_server;
            }
            last TRY;
        }

    } # retry as many times as there are servers

    if ( $eval_error ) {
        die "Final error ($n/$maxtries): $eval_error";
    }

    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::YARN::Roles::Common

=head1 VERSION

version 0.202

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
