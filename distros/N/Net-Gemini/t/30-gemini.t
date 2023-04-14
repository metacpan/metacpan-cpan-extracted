#!perl
#
# gemini client tests. there are various PORTABILITY problems for some
# of these tests (e.g. [rt.cpan.org #144920]); therefore, a bunch of
# them have been wrapped in AUTHOR_TEST_JMATES which assumes one is
# running on OpenBSD

use strict;
use warnings;
use Test2::V0;
plan 28;

use IO::Socket::SSL;
use Net::Gemini;
use Net::Gemini::Server;

# for the test servers. see also t/mkcertificate
my $The_Host = exists $ENV{GEMINI_HOST} ? $ENV{GEMINI_HOST} : '127.0.0.1';
my $The_Cert = exists $ENV{GEMINI_CERT} ? $ENV{GEMINI_CERT} : 't/host.cert';
my $The_Key  = exists $ENV{GEMINI_KEY}  ? $ENV{GEMINI_KEY}  : 't/host.key';

check_that( code => 0, err => qr/^source is not defined/ );
check_that(
    req  => 'http://example.org',
    code => 0,
    err  => qr/^could not parse/
);

my $long_uri = URI->new( 'gemini://example.org/' . ( 'a' x 1005 ) );
check_that(
    req  => $long_uri,
    code => 0,
    err  => qr/^URI is too long/
);
check_that(
    req   => "gemini://127.0.0.1:1965/",
    param => {
        ssl => { SSL_cert_file => "there is no such certificate file or so we hope" }
    },
    code => 0,
    err  => qr/^IO::Socket::SSL failed/
);

# PORTABILITY fiddly network tests that may run into portability
# problems depending on exactly how the socket connection falls
# apart; these assume an OpenBSD test host so will likely need
# adjustment elsewhere
SKIP: {
    skip( "no author tests", 6 ) unless $ENV{AUTHOR_TEST_JMATES};
    {
        my ( $pid, $port ) =
          with_server( sub { die "not reached" }, close_on_accept => 1 );
        check_that(
            req  => "gemini://$The_Host:$port/",
            code => 0,
            err  => qr/^IO::Socket::SSL failed/,
        );
        kill SIGTERM => $pid;
    }
    {
        # this callback might well be reached by the server
        my ( $pid, $port ) =
          with_server( sub { }, no_ssl => 1 );
        check_that(
            req  => "gemini://$The_Host:$port/",
            code => 0,
            err  => qr/^IO::Socket::SSL failed: SSL connect/,
        );
        kill SIGTERM => $pid;
    }
    {
        my ( $pid, $port ) =
          with_server( sub { die "not reached" }, close_before_read => 1 );
        check_that(
            req   => "gemini://$The_Host:$port/",
            param => { ssl => { SSL_ca_file => $The_Cert, } },
            code  => 0,
            err   => qr/^recv EOF/,
        );
        kill SIGTERM => $pid;
    }
    # NOTE close_after_read gets the same recv EOF condition as above
}

# naughty server and a naughty client, mostly for code coverage
{
    #diag "server sleeps here ...";
    my ( $pid, $port ) = with_server(
        sub {
            my ( $socket, $length, $buffer ) = @_;
            $socket->print("1");
            $socket->flush;
            sleep 1;
            $socket->print("2");
            $socket->flush;
            sleep 1;
            # invalid status line, should instead be a space
            $socket->print("X");
            $socket->flush;
            close $socket;
        }
    );
    check_that(
        req   => "gemini://$The_Host:$port/",
        param => { bufsize => 1, ssl => { SSL_ca_file => $The_Cert, } },
        code  => 0,
        err   => qr/^invalid response 31\.32\.58/
    );
    kill SIGTERM => $pid;
}
{
    my ( $pid, $port ) = with_server(
        sub {
            my ( $socket, $length, $buffer ) = @_;
            # an invalid (too long!!) meta line
            while (1) {
                $socket->print("2");
                $socket->flush;
                $socket->print("2");
                $socket->flush;
                $socket->print(" ");
                $socket->flush;
            }
        }
    );
    check_that(
        req   => "gemini://$The_Host:$port/",
        param => { bufsize => 1, ssl => { SSL_ca_file => $The_Cert, } },
        code  => 0,
        err   => qr/^meta is too long/
    );
    kill SIGTERM => $pid;
}

{
    my ( $pid, $port ) = with_server(
        sub {
            my ( $socket, $length, $from_client ) = @_;
            $socket->print("22 text/plain\r\n$from_client");
            $socket->flush;
            die "this is for better code coverage?\n";
        }
    );

    my $uri = "gemini://$The_Host:$port/test";
    my ( $gem, $code ) =
      Net::Gemini->get( $uri, ssl => { SSL_ca_file => $The_Cert } );
    is( $gem->code,    2 ) or diag $gem->error;
    is( $gem->content, "$uri\r\n" );
    is( $gem->error,   undef );
    is( $gem->host,    $The_Host );
    is( $gem->meta,    'text/plain' );
    is( $gem->port,    $port );
    is( $gem->socket,  D() );
    is( $gem->status,  22 );
    is( $gem->uri,     $uri );

    my $body = '';
    $gem->getmore(
        sub {
            my ( $buffer, $length ) = @_;
            $body .= $buffer;
            return 1;
        }
    );
    is( $body, "$uri\r\n" );

    kill SIGTERM => $pid;
}

exit;

########################################################################
#
# SUBROUTINES

sub check_that {
    my %param = @_;
    # KLUGE skip() for the tricky tests then causes the test count to
    # fall apart; probably need to do the skip here due to the context
    # and also prevent the test servers from starting? I the meantime
    # just skip context() in that context
    my $ctx;
    $ctx = context() unless $ENV{AUTHOR_TEST_JMATES};
    my ( $gem, $code ) = Net::Gemini->get( $param{req},
        exists $param{param} ? %{ $param{param} } : () );
    is( $code, $param{code} );
    like( $gem->{_error}, $param{err} );
    $ctx->release unless $ENV{AUTHOR_TEST_JMATES};
}

sub with_server {
    my $server = Net::Gemini::Server->new(
        listen => {
            LocalAddr => $The_Host,
            LocalPort => 0,           # get a random port
        },
        context => {
            SSL_cert_file => $The_Cert,
            SSL_key_file  => $The_Key,
        }
    );
    my $port = $server->port;
    my $pid  = fork;
    bail_out("fork failed: $!") unless defined $pid;
    unless ($pid) {
        $server->withforks(@_);
        diag "server left listen loop??\n";
        exit 1;
    }
    close $server->socket;
    return ( $pid, $port );
}
