package t::lib::Test;

use 5.006;
use strict;
use warnings;
use parent 'Test::Builder::Module';

BEGIN {
    if (!$ENV{REMOTE_DEBUGGER}) {
        require Devel::Debug::DBGp;

        $ENV{REMOTE_DEBUGGER} = Devel::Debug::DBGp->debugger_path;
    }

    die "\$ENV{REMOTE_DEBUGGER} not set" unless $ENV{REMOTE_DEBUGGER};
    die "\$ENV{REMOTE_DEBUGGER} not set correctly" unless
        -f "$ENV{REMOTE_DEBUGGER}/perl5db.pl";
}

use Test::More;
use Test::DBGp;
use HTTP::CookieJar;

use IPC::Open3 ();
use MIME::Base64 qw(encode_base64);
use Storable qw(thaw);
use Symbol;
use Cwd;

require feature;

our @EXPORT = (
  @Test::More::EXPORT,
  @Test::DBGp::EXPORT,
  qw(
        abs_uri
        run_app
        wait_app
        send_command
        command_is
        init_is
        eval_value_is
        start_listening
        stop_listening
        wait_connection
        discard_connection
        send_request
        response_is
  )
);

sub import {
    unshift @INC, 't/lib';

    strict->import;
    warnings->import;
    feature->import(':5.10');

    goto &Test::Builder::Module::import;
}

my ($HTTP_PORT);
my ($PID, $CHILD_IN, $CHILD_OUT, $CHILD_ERR);
my ($REQ_PID, $REQ_OUT, $REQ_ERR);

sub abs_uri {
    return 'file://' . Cwd::abs_path($_[0]);
}

sub start_listening { dbgp_listen() }
sub stop_listening { dbgp_stop_listening() }

sub run_app {
    my ($app) = @_;

    for my $port (17000 .. 19000) {
        my $sock = IO::Socket::INET->new(
            Listen    => 1,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            Timeout   => 5,
        );
        next unless $sock;

        $HTTP_PORT = $port;
        last;
    }

    die "Unable to find a free port for HTTP in the 17000 - 19000 port range"
        unless $HTTP_PORT;

    local $ENV{DEBUGGER_PORT} = dbgp_listening_port();
    local $ENV{DEBUGGER_PATH} = dbgp_listening_path();
    $CHILD_ERR = gensym;
    $PID = IPC::Open3::open3(
        $CHILD_IN, $CHILD_OUT, $CHILD_ERR,
        $^X, ($INC{'blib.pm'} ? ('-Mblib') : ()),
        't/scripts/plackup.pl',
        '-o', 'localhost', '-p', $HTTP_PORT,
        $app,
    );
}

sub wait_app {
    die "Call run_app() first" unless $PID;

    for (1 .. 5) {
        eval {
            IO::Socket::INET->new(
                PeerAddr => 'localhost',
                PeerPort => $HTTP_PORT,
            );
        } or do {
            sleep 1;
            next;
        };
        return;
    }

    kill 9, $PID;
    waitpid $PID, 0 unless $^O eq 'MSWin32';

    local $/;
    my $out = readline $CHILD_OUT;
    my $err = readline $CHILD_ERR;

    die "application did not start up in time\n",
        "STDOUT:\n$out\n" x !!$out,
        "STDERR:\n$err\n" x !!$err;
}

sub send_request {
    my ($path, $cookie) = @_;

    wait_app();
    $REQ_ERR = gensym;
    $REQ_PID = IPC::Open3::open3(
        my $req_in, $REQ_OUT, $REQ_ERR,
        $^X, 't/scripts/curl.pl', "http://localhost:$HTTP_PORT$path",
        (($cookie) x !!defined $cookie),
    );
}

sub response_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($content, $cookie) = @_;

    die "No pending request" unless $REQ_PID;
    waitpid $REQ_PID, 0;
    my $rc = $?;

    my ($out, $err);
    {
        local $/;

        $out = readline $REQ_OUT;
        $err = readline $REQ_ERR;
    }

    if ($rc) {
        note("STDERR");
        note($err);
        fail("Something went wrong with the request");
    } else {
        my $res = thaw($out);

        if ($res->{status} != 200) {
            note($res->{content});
            fail("Response is a failure");
        } else {
            is($res->{content}, $content, 'response content matches');

            if ($cookie) {
                my $header = $res->{headers}{'set-cookie'} // '';
                my ($value) = split /;/, $header;

                is($value, $cookie->{value}, '  cookie value matches');

                if (exists $cookie->{expires}) {
                    my $jar = HTTP::CookieJar->new;
                    $jar->add("http://localhost:$HTTP_PORT/", $header)
                        or die "Failed to process header";
                    my ($res_cookie) = $jar->cookies_for("http://localhost:$HTTP_PORT/");
                    if ($cookie->{expires} == -1) {
                        is($res_cookie, undef, '  cookie is expired');
                    } else {
                        cmp_ok(abs($res_cookie->{expires} - time - $cookie->{expires}), '<', 10, '  cookie expiration time is (approximately) as expected');
                    }
                }
            }
        }
    }
}

sub wait_connection { dbgp_wait_connection($PID, @_) }
sub discard_connection { dbgp_wait_connection($PID, 'reject') }

sub send_command { dbgp_send_command(@_) }

sub init_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    dbgp_init_is(@_);
}

sub command_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    dbgp_command_is(@_);
}

sub eval_value_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($expr, $value) = @_;
    my $res = send_command('eval', encode_base64($expr));

    is($res->result->value, $value);
}

sub _cleanup {
    return unless $PID;
    kill 9, $PID;
}

END { _cleanup() }

1;
