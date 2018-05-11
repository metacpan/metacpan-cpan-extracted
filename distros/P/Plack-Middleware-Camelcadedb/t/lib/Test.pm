package t::lib::Test;

use 5.006;
use strict;
use warnings;
use parent 'Test::Builder::Module';

use Test::More;

use IPC::Open3 ();
use Storable qw(thaw);
use Symbol;
use Cwd;

require feature;

our @EXPORT = (
  @Test::More::EXPORT,
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
    my ($path) = @_;

    wait_app();
    $REQ_ERR = gensym;
    $REQ_PID = IPC::Open3::open3(
        my $req_in, $REQ_OUT, $REQ_ERR,
        $^X, 't/scripts/curl.pl', "http://localhost:$HTTP_PORT$path",
    );
}

sub response_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($content) = @_;

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
        }
    }
}

sub _cleanup {
    return unless $PID;
    kill 9, $PID;
}

END { _cleanup() }

1;
