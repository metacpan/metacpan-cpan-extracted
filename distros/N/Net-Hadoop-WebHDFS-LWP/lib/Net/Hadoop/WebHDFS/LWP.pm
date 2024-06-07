package Net::Hadoop::WebHDFS::LWP;
$Net::Hadoop::WebHDFS::LWP::VERSION = '0.012';
use strict;
use warnings;
use parent 'Net::Hadoop::WebHDFS';

# VERSION

use LWP::UserAgent;
use Carp;
use Ref::Util    qw( is_arrayref );
use Scalar::Util qw( openhandle );
use HTTP::Request::StreamingUpload;

use constant UA_PASSTHROUGH_OPTIONS => qw(
    cookie_jar
    env_proxy
    no_proxy
    proxy
);

sub new {
    my $class   = shift;
    my %options = @_;
    my $debug   = delete $options{debug} || 0;
    my $use_ssl = delete $options{use_ssl} || 0;

    require Data::Dumper if $debug;

    my $self = $class->SUPER::new(@_);

    # we don't need Furl
    delete $self->{furl};

    $self->{debug} = $debug;

    # default timeout is a bit short, raise it
    $self->{timeout}   = $options{timeout}   || 30;

    # For filehandle upload support
    $self->{chunksize} = $options{chunksize} || 4096;

    $self->{ua_opts} = {
        map {
            exists $options{$_} ? (
                $_ => $options{ $_ }
            ) : ()
        } UA_PASSTHROUGH_OPTIONS
    };

    $self->_create_ua;

    $self->{use_ssl} = $use_ssl;

    return $self;
}

# Code below copied and modified for LWP from Net::Hadoop::WebHDFS
#
sub request {
    my ( $self, $host, $port, $method, $path, $op, $params, $payload, $header ) = @_;

    my $request_path = $op ? $self->build_path( $path, $op, %$params ) : $path;

    my $protocol = $self->{use_ssl} ? 'https' : 'http';

    # Note: ugly things done with URI, which is already used in the parent
    # module. So we re-parse the path produced there. yuk.
    my $uri = URI->new( $request_path, $protocol );

    $uri->host($host);
    $uri->port($port);

    $uri->scheme( $protocol );

    printf STDERR "URI : %s\n", $uri if $self->{debug};

    my $req;

    if ( $payload && openhandle($payload) ) {
        $req = HTTP::Request::StreamingUpload->new(
            $method => $uri,
            fh      => $payload,
            headers    => HTTP::Headers->new( 'Content-Length' => -s $payload, ),
            chunk_size => $self->{chunksize},
        );
    }
    elsif ( ref $payload ) {
        croak __PACKAGE__ . " does not accept refs as content, only scalars and FH";
    }
    else {
        $req = HTTP::Request->new( $method => $uri );
        $req->content($payload);
    }

    if ( is_arrayref( $header ) ) {
        while ( my ( $h_field, $h_value ) = splice( @{ $header }, 0, 2 ) ) {
            $req->header( $h_field => $h_value );
        }
    }

    my $real_res = $self->{ua}->request($req);

    my $res = { code => $real_res->code, body => $real_res->decoded_content };
    my $code = $real_res->code;

    printf STDERR "HTTP code : %s\n", $code if $self->{debug};

    my $headers = $real_res->headers;

    printf STDERR "Headers: %s", Data::Dumper::Dumper $headers if $self->{debug};

    for my $h_key ( keys %{ $headers || {} } ) {
        my $h_value = $headers->{$h_key};

        if    ( $h_key =~ m!^location$!i )     { $res->{location}     = $h_value; }
        elsif ( $h_key =~ m!^content-type$!i ) { $res->{content_type} = $h_value; }
    }

    return $res if $res->{code} >= 200 and $res->{code} <= 299;
    return $res if $res->{code} >= 300 and $res->{code} <= 399;

    my $errmsg = $res->{body} || 'Response body is empty...';
    $errmsg =~ s/\n//g;

    # Attempt to strigfy the HTML message
    if ( $errmsg =~ m{ \A <html.+?> }xmsi ) {
        if ( my @errors = $self->_parse_error_from_html( $errmsg ) ) {
            # @error can also be assigned to a hash as it is mapped
            # to kay=>value pairs, however strigifying the message
            # is enough for now
            my @flat;
            while ( my ( $key, $val ) = splice( @errors, 0, 2 ) ) {
                push @flat, "$key: $val"
            }
            # reset to something meaningful now that we've removed the html cruft
            $errmsg = join '. ', @flat;
        }
    }

    if ( $code == 400 ) {
        croak "ClientError: $errmsg";
    }
    elsif ( $code == 401 ) {
        # this error happens for secure clusters when using Net::Hadoop::WebHDFS,
        # but LWP::Authen::Negotiate takes care of it transparently in this module.
        # we still may get this error on a secure cluster, when the credentials
        # cache hasn't been initialized
        my $extramsg = ( $headers->{'www-authenticate'} || '' ) eq 'Negotiate'
            ? eval { require LWP::Authen::Negotiate; 1; }
                ? q{ (Did you forget to run kinit?)}
                : q{ (LWP::Authen::Negotiate doesn't seem available)}
            : '';
        croak "SecurityError$extramsg: $errmsg";
    }
    elsif ( $code == 403 ) {
        if ( $errmsg =~ m{ \Qorg.apache.hadoop.ipc.StandbyException\E }xms ) {
            if ( $self->{httpfs_mode} || not defined( $self->{standby_host} ) ) {

                # failover is disabled
            }
            elsif ( $self->{retrying} ) {

                # more failover is prohibited
                $self->{retrying} = 0;
            }
            else {
                $self->{under_failover} = not $self->{under_failover};
                $self->{retrying}       = 1;
                my ( $next_host, $next_port ) = $self->connect_to;
                my $val = $self->request(
                                $next_host,
                                $next_port,
                                $method,
                                $path,
                                $op,
                                $params,
                                $payload,
                                $header,
                            );
                $self->{retrying} = 0;
                return $val;
            }
        }
        croak "IOError: $errmsg";
    }
    elsif ( $code == 404 ) {
        croak "FileNotFoundError: $errmsg";
    }
    elsif ( $code == 500 ) {
        croak "ServerError: $errmsg";
    }
    else {
        # do nothing
    }

    # catch-all exception
    croak "RequestFailedError, code:$code, message:$errmsg";
}

sub _create_ua {
    my $self  = shift;
    my $class = ref $self;

    $self->{ua} = LWP::UserAgent->new(
                        requests_redirectable => [qw(
                            GET
                            HEAD
                            POST
                            PUT
                        )],
                        %{ $self->{ua_opts} },
                    );

    $self->{ua}->agent(
        sprintf "%s %s",
                    $class,
                    $class->VERSION || 'beta',
    );

    $self->{useragent} = $self->{ua}->agent;
    $self->{ua}->timeout( $self->{timeout} );

    return $self;
}

sub _parse_error_from_html {
    # This is a brittle function as it assumes certain things to be present
    # in the HTML output and will most likely break with future updates.
    # However the interface returns HTML in certain cases (like secure clusters)
    # and currently that's a failure on the backend where we can;t fix things.
    #
    # In any case, the program should default to the original message fetched,
    # if this fails for any reason.
    #
    my $self   = shift;
    my $errmsg = shift;

    if ( ! eval { require HTML::Parser;} ) {
        if ( $self->{debug} ) {
            printf STDERR "Tried to parse the HTML error message but HTML::Parser is not available!\n";
        }
        return;
    }

    my @errors;
    my $p = HTML::Parser->new(
                api_version => 3,
                handlers    => {
                    text => [
                        \@errors,
                        'event,text',
                    ],
                }
            );
    $p->parse( $errmsg );

    my @flat =  map {;
                    s{ \A \s+    }{}xmsg;
                    s{    \s+ \z }{}xmsg;
                    $_;
                }
                grep {
                       $_ !~ m{ \Q<!--\E    }xms # comment
                    && $_ !~ m{ \A Apache\b }xms # Tomcat version, etc.
                    && $_ !~ m{ \A \s+ \z   }xms # " "
                }
                map { $_->[1] }
                @errors;

    if ( @flat % 2 ) {
        unshift @flat, 'http_status';
    }

    return @flat;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::WebHDFS::LWP - Client library for Hadoop WebHDFS and HttpFs, with Kerberos support

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    use Net::Hadoop::WebHDFS::LWP;

    my $client = Net::Hadoop::WebHDFS::LWP->new(
        host        => 'webhdfs.local',
        port        => 14000,
        username    => 'jdoe',
        httpfs_mode => 1,
        use_ssl     => 1,
    );
    $client->create(
        '/foo/bar', # path
        "...",      # content
        permission => '644',
        overwrite => 'true'
    ) or die "Could not write to HDFS";

=head1 DESCRIPTION

This module is a quick and dirty hack to add Kerberos support to Satoshi
Tagomori's module L<Net::Hadoop::WebHDFS>, to access Hadoop secure clusters. It
simply subclasses the original module, replacing L<Furl> with L<LWP>, which
will transparently use L<LWP::Authen::Negotiate> when needed. So the real
documentation is contained in L<Net::Hadoop::WebHDFS>.

=head1 ACKNOWLEDGEMENTS

As mentioned above, the real work was done by Satoshi Tagomori

Thanks to my employer Booking.com to allow me to release this module for public use

=for Pod::Coverage request

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by David Morel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#ABSTRACT: Client library for Hadoop WebHDFS and HttpFs, with Kerberos support

