#!perl
# gemini client tests. there are various PORTABILITY problems for
# some of these tests (e.g. [rt.cpan.org #144920]); therefore, a
# bunch of them have been wrapped in AUTHOR_TEST_JMATES which assumes
# one is running on OpenBSD; these also may break if the OpenBSD
# folks change anything
use strict;
use warnings;
use IO::Socket::IP;
use IO::Socket::SSL;
use Net::Gemini 0.08 'gemini_request';
use Test2::V0;

use lib './t/lib';
use GemServ;

plan 50;

my $u = URI->new('gemini://example.org/');
# TODO not sure how to get coverage on the remainder of the
# URI::gemini code
is( $u->secure,   1 );
is( $u->userinfo, undef );

# for the test servers. see also t/mkcertificate
my $The_Host =
  exists $ENV{GEMINI_HOST} ? $ENV{GEMINI_HOST} : '127.0.0.1';
my $The_Cert =
  exists $ENV{GEMINI_CERT} ? $ENV{GEMINI_CERT} : 't/host.cert';
my $The_Key =
  exists $ENV{GEMINI_KEY} ? $ENV{GEMINI_KEY} : 't/host.key';

my $wsargs =
  { host => $The_Host, cert => $The_Cert, key => $The_Key };

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
        ssl => {
            SSL_cert_file => "there is no such certificate file or so we hope"
        }
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
        my ( $pid, $port ) = GemServ::with_server(
            $wsargs,
            sub { die "not reached" },
            close_on_accept => 1
        );
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
          GemServ::with_server( $wsargs, sub { }, no_ssl => 1 );
        check_that(
            req  => "gemini://$The_Host:$port/",
            code => 0,
            err  => qr/^IO::Socket::SSL failed: SSL connect/,
        );
        kill SIGTERM => $pid;
    }
    {
        my ( $pid, $port ) = GemServ::with_server(
            $wsargs,
            sub { die "not reached" },
            close_before_read => 1
        );
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
    my ( $pid, $port ) = GemServ::with_server(
        $wsargs,
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
    my ( $pid, $port ) = GemServ::with_server(
        $wsargs,
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
    my ( $pid, $port ) = GemServ::with_server(
        $wsargs,
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
    is( $gem->code,  2 ) or diag $gem->error;
    is( $gem->error, undef );
    is( $gem->host,  $The_Host );
    ok( length $gem->ip );   # for coverage, user might change GEMINI_HOST
    is( $gem->meta,   'text/plain;charset=utf-8' );
    is( $gem->port,   $port );
    is( $gem->socket, D() );
    is( $gem->status, 22 );
    is( $gem->uri,    $uri );

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

SKIP: {
    skip( "no author tests", 3 ) unless $ENV{AUTHOR_TEST_JMATES};
    {
        diag "blocking after an accept ...";
        my ( $pid, $port ) = with_server_terrible();
        my $uri = "gemini://$The_Host:$port/";
        my ( $gem, $code ) =
          Net::Gemini->get( $uri, tofu => 1, ssl => { Timeout => 3 } );
        is( $code, 0 );
        like( $gem->{_error}, qr/IO::Socket::SSL failed/ );
        kill SIGTERM => $pid;
    }

    {
        diag "blocking after start_SSL ...";
        my ( $pid, $port ) = with_server_terrible(1);
        my $uri = "gemini://$The_Host:$port/";
        my $ok  = eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 5;
            my ( $gem, $code ) =
              Net::Gemini->get( $uri, tofu => 1, ssl => { Timeout => 3 } );
            alarm 0;
            die "should not get here??\n";
        };
        is( $@, "timeout\n" );
        kill SIGTERM => $pid;
    }
}

# gemini_request
{
    my ( $pid, $port ) = GemServ::with_server(
        $wsargs,
        sub {
            my ( $socket, $length, $from_client ) = @_;
            if ( $from_client =~ m/smol/ ) {
                # META can be an empty string (in which case...)
                $socket->print("20 \r\nabcd");
            } elsif ( $from_client =~ m/bloat/ ) {
                $socket->print(
                    "20 text/plain;charset=us-ascii\r\nabcd" . "e" x 9999 );
            } elsif ( $from_client =~ m/special/ ) {
                $socket->print("20 TEXT/PLAIN\r\nfoo");
            } elsif ( $from_client =~ m/redirect1/ ) {
                substr $from_client, -2, 2, "/R\r\n";
                $socket->print("30 $from_client");
            }
            $socket->flush;
        }
    );
    my ( $uri, $gem, $code );

    # no META means the following implicit MIME type
    $uri = "gemini://$The_Host:$port/smol";
    ( $gem, $code ) = gemini_request($uri);
    is( $gem->content, 'abcd' );
    is( $gem->mime,    [ 'text', 'gemini', { charset => 'utf-8' } ] );

    ( $gem, $code ) = gemini_request(
        $uri,
        content_callback => sub {
            my ( $buf, $len, $obj ) = @_;
            is( $buf, 'abcd' );
            is( $len, 4 );
            ok( defined $obj );
            return 0;
        }
    );

    # custom charset
    $uri = "gemini://$The_Host:$port/bloat";
    ( $gem, $code ) = gemini_request($uri);
    is( $gem->mime, [ 'text', 'plain', { charset => 'us-ascii' } ] );
    is( length $gem->content, 10003 );

    # UTF-8 is the default if there's a "text/" but no charset
    $uri = "gemini://$The_Host:$port/special";
    ( $gem, $code ) = gemini_request($uri);
    is( $gem->mime, [ 'TEXT', 'PLAIN', { charset => 'utf-8' } ] );

    diag("redirects may be slow ...");
    $uri = "gemini://$The_Host:$port/redirect1";
    ( $gem, $code ) = gemini_request($uri);
    # NOTE '3' here means we're tapped out on redirects, unlike for get
    # which only makes a single request
    is( $gem->code, 3 );
    like( $gem->uri, qr{/redirect1/R/R/R/R/R$} );

    ( $gem, $code ) =
      gemini_request( $uri, max_redirects => 3, redirect_delay => 0.25 );
    like( $gem->uri, qr{/redirect1/R/R/R$} );

    # custom buffer sizes, for code coverage. the param bufsize is for
    # the ->get call, and the other is for gemini_request
    $uri = "gemini://$The_Host:$port/bloat";
    ( $gem, $code ) = gemini_request(
        $uri,
        max_size => 10,
        bufsize  => 8,
        param    => { bufsize => 1 }
    );
    # is there a better way to signal that the content is truncated? :/
    is( $gem->code,    0 );              # error!
    is( $gem->status,  20 );             # not error!
    is( $gem->error,   'max_size' );     # error!
    is( $gem->content, 'abcdeeeeee' );

    # and that getmore bufsize gets tested
    ( $gem, $code ) = Net::Gemini->get(
        $uri,
        bufsize => 1,
        tofu    => 1,
        ssl     => { SSL_ca_file => $The_Cert }
    );
    $gem->getmore(
        sub {
            my ( $buf, $len ) = @_;
            is( $buf, 'a' );
            return 0;
        },
        bufsize => 1
    );

    kill SIGTERM => $pid;
}

# some Server.pm code coverage, should get a "handshake failed" warning
SKIP: {
    skip( "no author tests", 1 ) unless $ENV{AUTHOR_TEST_JMATES};
    my ( $pid, $port ) = GemServ::with_server(
        { %$wsargs, buggy_context => 1 },
        sub {
            my ( $s, $len, $buf ) = @_;
            $s->print("20 \r\nok");
            close $s;
        },
    );

    my $uri = "gemini://$The_Host:$port";
    my ( $gem, $code ) =
      Net::Gemini->get( $uri, ssl => { SSL_ca_file => $The_Cert } );
    is( $code, 0 );

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

sub with_server_terrible {
    my ( $mode, $timeout ) = @_;
    $timeout = 33 unless $timeout;
    my $sock = IO::Socket::IP->new(
        Listen    => 5,
        Reuse     => 1,
        LocalAddr => $The_Host,
        LocalPort => 0,
    ) or bail_out("server failed: $!");
    my $context = IO::Socket::SSL::SSL_Context->new(
        SSL_server    => 1,
        SSL_cert_file => $The_Cert,
        SSL_key_file  => $The_Key,
    ) or bail_out("context failed: $SSL_ERROR");
    my $port = $sock->sockport;
    my $pid  = fork;
    bail_out("fork failed: $!") unless defined $pid;

    unless ($pid) {
        while (1) {
            my $client = $sock->accept;
            unless ($mode) {
                sleep $timeout;
            } else {
                IO::Socket::SSL->start_SSL(
                    $client,
                    SSL_server    => 1,
                    SSL_reuse_ctx => $context
                ) or bail_out("ssl handshake failed: $SSL_ERROR");
                sleep $timeout;
            }
            close $client;
        }
    }
    close $sock;
    return $pid, $port;
}
