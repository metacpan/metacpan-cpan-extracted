#!/usr/bin/env perl

# =============================================================================
# Runner/Server integration tests
#
# PROVENANCE: These subtests were relocated from PAGI-Tools to PAGI-Server
# because they exercise a real PAGI::Server (real sockets, real event loop,
# SSL-cert rejection, PID-file lifecycle with a forked server process).
#
# Original sources:
#   - Subtests 1-6: PAGI-Tools t/runner.t
#   - Subtest 7:    PAGI-Tools t/25-runner-production.t
#
# PAGI::Server::Runner ships in this distribution. The integration tests
# exercise toolkit modules (PAGI::App::*, PAGI::Test::Client) that live in
# PAGI-Tools. Run with PAGI-Tools lib bridged for those modules:
#   PERL5LIB=/path/to/PAGI-Tools/lib:$PERL5LIB prove -lv t/integration/runner-server.t
# =============================================================================

use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../../lib";

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

use IO::Async::Loop;
use Net::Async::HTTP;
use Future::AsyncAwait;
use File::Temp qw(tempdir tempfile);

use PAGI::Server;
use PAGI::Server::Runner;

# ---------------------------------------------------------------------------
# SOURCE: t/runner.t
# SUBTEST: 'load_server dies without app'
# NOTE: This tested PAGI::Server->new(app => undef) dying, not Runner logic.
#       Runner::load_server does NOT die when app is undef — it passes undef
#       to the server constructor. The die came from PAGI::Server.
# ---------------------------------------------------------------------------
subtest 'load_server dies without app' => sub {
    my $runner = PAGI::Server::Runner->new;

    like(
        dies { $runner->load_server },
        qr/app/i,
        'dies without app'
    );
};

# ---------------------------------------------------------------------------
# SOURCE: t/runner.t
# SUBTEST: 'integration: server responds to requests'
# ---------------------------------------------------------------------------
subtest 'integration: server responds to requests' => sub {
    my $loop = IO::Async::Loop->new;

    my $runner = PAGI::Server::Runner->new(port => 0, quiet => 1);
    $runner->{app_spec} = "$FindBin::Bin/../../examples/01-hello-http/app.pl";
    $runner->{default_middleware} = 0;  # Disable Lint for test
    $runner->prepare_app;
    my $server = $runner->load_server;

    $loop->add($server);
    $server->listen->get;

    my $port = $server->port;
    ok($port > 0, "server bound to port $port");

    my $http = Net::Async::HTTP->new;
    $loop->add($http);

    my $response = $http->GET("http://127.0.0.1:$port/")->get;

    is($response->code, 200, 'response is 200 OK');
    like($response->decoded_content, qr/Hello from PAGI/, 'correct response body');

    $server->shutdown->get;
    $loop->remove($server);
    $loop->remove($http);
};

# ---------------------------------------------------------------------------
# SOURCE: t/runner.t
# SUBTEST: 'integration: module-based app serves files'
# ---------------------------------------------------------------------------
subtest 'integration: module-based app serves files' => sub {
    skip_all 'PAGI::App::File not available (install PAGI-Tools >= 0.002000)'
        unless eval { require PAGI::Tools; PAGI::Tools->VERSION(0.002000); require PAGI::App::File; 1 };
    my $loop = IO::Async::Loop->new;

    # Create a temp directory with a file
    my $tmpdir = tempdir(CLEANUP => 1);
    open my $fh, '>', "$tmpdir/test.txt" or die $!;
    print $fh "Hello from test file";
    close $fh;

    my $runner = PAGI::Server::Runner->new(port => 0, quiet => 1);
    $runner->{argv} = ['PAGI::App::File', "root=$tmpdir"];
    $runner->{default_middleware} = 0;  # Disable Lint for test
    $runner->prepare_app;
    my $server = $runner->load_server;

    $loop->add($server);
    $server->listen->get;

    my $port = $server->port;

    my $http = Net::Async::HTTP->new;
    $loop->add($http);

    my $response = $http->GET("http://127.0.0.1:$port/test.txt")->get;

    is($response->code, 200, 'file served with 200');
    is($response->decoded_content, 'Hello from test file', 'correct file content');

    $server->shutdown->get;
    $loop->remove($server);
    $loop->remove($http);
};

# ---------------------------------------------------------------------------
# SOURCE: t/runner.t
# SUBTEST: 'SSL options validation'
# NOTE: The real-server half — PAGI::Server validates the cert file path in
#       its constructor. The agnostic half (ssl config passthrough) is now
#       covered in Tools by the rewritten 'load_server creates server' subtest.
# ---------------------------------------------------------------------------
subtest 'SSL options validation' => sub {
    skip_all 'PAGI::App::Directory not available (install PAGI-Tools >= 0.002000)'
        unless eval { require PAGI::Tools; PAGI::Tools->VERSION(0.002000); require PAGI::App::Directory; 1 };
    my $runner = PAGI::Server::Runner->new(
        quiet          => 1,
        server_options => {
            ssl => { cert_file => '/nonexistent/cert.pem', key_file => '/nonexistent/key.pem' },
        },
    );
    $runner->prepare_app;

    like(
        dies { $runner->load_server },
        qr/SSL certificate file not found/,
        'dies with invalid SSL cert path'
    );
};

# ---------------------------------------------------------------------------
# SOURCE: t/runner.t
# SUBTEST: 'load_server with socket option omits host/port'
# NOTE: The real-server introspection half — asserts on PAGI::Server-specific
#       methods (socket_path, port). The agnostic half (socket key passthrough
#       and host/port omission) is now covered in Tools via FakeServer.
# ---------------------------------------------------------------------------
subtest 'load_server with socket option omits host/port (PAGI::Server introspection)' => sub {
    skip_all 'PAGI::App::Directory not available (install PAGI-Tools >= 0.002000)'
        unless eval { require PAGI::Tools; PAGI::Tools->VERSION(0.002000); require PAGI::App::Directory; 1 };
    my $socket_path = File::Temp::tmpnam() . '.sock';
    my $runner = PAGI::Server::Runner->new(
        quiet          => 1,
        server_options => { socket => $socket_path },
    );
    $runner->prepare_app;
    my $server = $runner->load_server;

    ok($server->isa('PAGI::Server'), 'returns PAGI::Server');
    is($server->socket_path, $socket_path, 'socket_path set correctly');
    is($server->port, undef, 'port is undef for socket server');
};

# ---------------------------------------------------------------------------
# SOURCE: t/runner.t
# SUBTEST: 'load_server with listen option omits host/port'
# NOTE: The real-server introspection half — asserts on PAGI::Server-specific
#       accessors (listeners, listener type). The agnostic half is now in Tools.
# ---------------------------------------------------------------------------
subtest 'load_server with listen option omits host/port (PAGI::Server introspection)' => sub {
    skip_all 'PAGI::App::Directory not available (install PAGI-Tools >= 0.002000)'
        unless eval { require PAGI::Tools; PAGI::Tools->VERSION(0.002000); require PAGI::App::Directory; 1 };
    my $socket_path = File::Temp::tmpnam() . '.sock';
    my $runner = PAGI::Server::Runner->new(
        quiet          => 1,
        server_options => {
            listen => [
                { host => '127.0.0.1', port => 0 },
                { socket => $socket_path },
            ],
        },
    );
    $runner->prepare_app;
    my $server = $runner->load_server;

    ok($server->isa('PAGI::Server'), 'returns PAGI::Server');
    my $listeners = $server->listeners;
    is(scalar @$listeners, 2, 'two listeners configured');
    is($listeners->[0]{type}, 'tcp', 'first listener is tcp');
    is($listeners->[1]{type}, 'unix', 'second listener is unix');
};

# ---------------------------------------------------------------------------
# SOURCE: t/25-runner-production.t
# SUBTEST: 'PID file with actual server process'
# NOTE: This runs an actual PAGI::Server event loop (load_server + listen +
#       loop->run). Tests the integration between Runner's PID-file lifecycle
#       and a real server process. Belongs in PAGI-Server.
# ---------------------------------------------------------------------------
subtest 'PID file with actual server process' => sub {
    my ($fh, $pid_file) = tempfile(UNLINK => 1);
    close $fh;
    unlink $pid_file;

    # Fork a server process that actually runs
    my $server_pid = fork();
    die "Cannot fork: $!" unless defined $server_pid;

    if ($server_pid == 0) {
        # Child - start actual server
        my $runner = PAGI::Server::Runner->new(
            port     => 0,  # Random port
            quiet    => 1,
            pid_file => $pid_file,
        );
        $runner->{app_spec} = "$FindBin::Bin/../../examples/01-hello-http/app.pl";
        $runner->{default_middleware} = 0;  # Disable Lint for test
        $runner->prepare_app;

        # Write PID file before running
        $runner->_write_pid_file($pid_file);

        # Install signal handlers for proper cleanup on ALRM or TERM
        # Without these, alarm(2) kills the process before _remove_pid_file runs
        local $SIG{ALRM} = sub {
            $runner->_remove_pid_file;
            exit(0);
        };
        local $SIG{TERM} = sub {
            $runner->_remove_pid_file;
            exit(0);
        };

        # Run for a short time then exit
        alarm(2);  # Exit after 2 seconds

        eval {
            my $server = $runner->load_server;
            require IO::Async::Loop;
            my $loop = IO::Async::Loop->new;
            $loop->add($server);
            $server->listen->get;
            $loop->run;
        };

        # Clean up PID file on exit (normal exit path)
        $runner->_remove_pid_file;
        exit(0);
    }

    # Parent - wait for PID file to be created.
    # Budget is generous: child must load PAGI::Server::Runner fresh from lib/.
    my $retries = 60;
    while ($retries-- > 0 && !-f $pid_file) {
        select(undef, undef, undef, 0.1);
    }

    ok(-f $pid_file, 'Server created PID file');

    if (-f $pid_file) {
        open(my $pfh, '<', $pid_file);
        my $written_pid = <$pfh>;
        chomp $written_pid;
        close $pfh;

        is($written_pid, $server_pid, 'PID file contains server PID');
    }

    # Kill the server
    kill 'TERM', $server_pid;
    waitpid($server_pid, 0);

    # Give it time to clean up
    select(undef, undef, undef, 0.1);

    ok(!-f $pid_file, 'Server cleaned up PID file on exit');
};

done_testing;
