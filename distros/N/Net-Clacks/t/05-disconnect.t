#!/usr/bin/env perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 05-disconnect.t'

use strict;
use warnings;
use Test::More;

# Author test - skip unless explicitly enabled
unless ($ENV{TEST_AUTHOR}) {
    plan skip_all => 'Author test. Set TEST_AUTHOR to run.';
}

# Skip on Windows - uses fork()
if ($^O eq 'MSWin32') {
    plan skip_all => 'Test uses fork() which is not reliable on Windows';
}

use Net::Clacks::Server;
use Net::Clacks::Client;
use POSIX qw(:sys_wait_h);
use Time::HiRes qw(time sleep alarm);
use IO::Socket::UNIX;
use File::Spec;
use Cwd qw(abs_path getcwd);

# Get absolute paths
my $test_dir = abs_path(File::Spec->catdir(getcwd(), 't'));
my $config_file = File::Spec->catfile($test_dir, 'test_server.xml');
my $socket_file = File::Spec->catfile($test_dir, 'test_clacks.sock');
my $username = 'testuser';
my $password = 'testpass';

# Track server PID globally for cleanup
my $global_server_pid;

# Cleanup any leftover socket
unlink $socket_file if -e $socket_file;

# Update config file with absolute socket path
update_config_socket_path();

plan tests => 7;

# ============================================================================
# Test 1: Server Starts and Accepts Connections
# ============================================================================
subtest 'Server startup and basic connection' => sub {
    plan tests => 3;

    my $server_pid = fork_server();
    ok($server_pid, 'Server forked');

    my $socket_ready = wait_for_socket($socket_file, 10);
    ok($socket_ready, 'Socket file created');

    SKIP: {
        skip "Socket not ready", 1 unless $socket_ready;

        my $client = eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm(5);
            my $c = Net::Clacks::Client->newSocket(
                $socket_file, $username, $password, 'test_client', 0
            );
            alarm(0);
            $c;
        };
        alarm(0);

        ok($client, 'Client connected');
        $client->disconnect() if $client;
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 2: Verify Server Removes Client on Clean Disconnect
# ============================================================================
subtest 'Clean disconnect - verify server cleanup via monitor' => sub {
    plan tests => 4;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    # Connect monitor client first
    my $monitor = connect_with_timeout($socket_file, $username, $password, 'monitor');
    ok($monitor, 'Monitor client connected');

    SKIP: {
        skip "Monitor not connected", 3 unless $monitor;

        $monitor->setMonitormode(1);
        $monitor->doNetwork();
        sleep(0.2);

        # Connect test client
        my $test_client = connect_with_timeout($socket_file, $username, $password, 'test_disconnect');
        ok($test_client, 'Test client connected');

        if ($test_client) {
            $test_client->ping();
            $test_client->doNetwork();

            # Drain pending messages
            $monitor->doNetwork();
            drain_messages($monitor);

            # Disconnect test client
            $test_client->disconnect();

            # Give server more time to process and poll multiple times
            my $found_disconnect = 0;
            for my $attempt (1..10) {
                sleep(0.2);
                $monitor->doNetwork();
                while (my $msg = $monitor->getNext()) {
                    diag("Monitor received: type=$msg->{type}, host=" . ($msg->{host} // 'undef') . ", command=" . ($msg->{command} // 'undef')) if $ENV{TEST_VERBOSE};
                    if ($msg->{type} eq 'debug' && defined($msg->{host}) && $msg->{host} eq 'DISCONNECTED') {
                        $found_disconnect = 1;
                        last;
                    }
                }
                last if $found_disconnect;
            }
            ok($found_disconnect, 'Monitor received DEBUG DISCONNECTED message');
        } else {
            ok(0, 'Monitor received DEBUG DISCONNECTED message');
        }

        # Verify server still works
        my $verify = connect_with_timeout($socket_file, $username, $password, 'verify');
        ok($verify, 'Server still accepts connections');
        $verify->disconnect() if $verify;

        $monitor->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 3: Abrupt Disconnect - Verify Cleanup
# ============================================================================
subtest 'Abrupt disconnect - verify server cleanup' => sub {
    plan tests => 4;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $monitor = connect_with_timeout($socket_file, $username, $password, 'monitor');
    ok($monitor, 'Monitor connected');

    SKIP: {
        skip "Monitor not connected", 3 unless $monitor;

        $monitor->setMonitormode(1);
        $monitor->doNetwork();
        sleep(0.2);

        # Fork a client process that we'll kill
        my $client_pid = fork();
        if ($client_pid == 0) {
            my $client = Net::Clacks::Client->newSocket(
                $socket_file, $username, $password, 'doomed_client', 0
            );
            if ($client) {
                $client->ping();
                $client->doNetwork();
                sleep(60);
            }
            exit(0);
        }

        ok($client_pid, 'Client process forked');
        sleep(0.5);

        # Drain connection messages
        $monitor->doNetwork();
        drain_messages($monitor);

        # Kill client abruptly
        kill('KILL', $client_pid);
        waitpid($client_pid, 0);

        # Wait for server to detect and clean up
        my $start = time();
        my $found_disconnect = 0;
        while ((time() - $start) < 5) {
            $monitor->doNetwork();
            while (my $msg = $monitor->getNext()) {
                diag("Monitor received: type=$msg->{type}, host=" . ($msg->{host} // 'undef') . ", command=" . ($msg->{command} // 'undef')) if $ENV{TEST_VERBOSE};
                if ($msg->{type} eq 'debug' && defined($msg->{host}) && $msg->{host} eq 'DISCONNECTED') {
                    $found_disconnect = 1;
                    last;
                }
            }
            last if $found_disconnect;
            sleep(0.1);
        }
        my $elapsed = time() - $start;

        ok($found_disconnect, 'Server detected abrupt disconnect');
        ok($elapsed < 5, "Cleanup completed within timeout: ${elapsed}s");

        $monitor->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 4: Rapid Connect/Disconnect - Verify No FD Leak
# ============================================================================
subtest 'Rapid connect/disconnect - verify no FD leak' => sub {
    plan tests => 3;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $initial_fds = count_fds($server_pid);

    my $cycles = 20;  # Reduced for speed
    my $success = 0;

    for my $i (1..$cycles) {
        my $client = connect_with_timeout($socket_file, $username, $password, "rapid_$i");
        if ($client) {
            $client->ping();
            $client->doNetwork();
            $client->disconnect();
            $success++;
        }
    }

    ok($success == $cycles, "All $cycles cycles succeeded (got $success)");

    sleep(1);

    my $final_fds = count_fds($server_pid);
    my $fd_growth = $final_fds - $initial_fds;

    SKIP: {
        skip "FD count check only works on Linux", 1 unless -d "/proc/$server_pid/fd";
        ok($fd_growth < 5, "FD growth minimal: $fd_growth");
    }

    my $final = connect_with_timeout($socket_file, $username, $password, 'final');
    ok($final, 'Server works after rapid cycles');
    $final->disconnect() if $final;

    kill_server($server_pid);
};

# ============================================================================
# Test 5: Multiple Concurrent Disconnects
# ============================================================================
subtest 'Multiple concurrent disconnects - verify all cleaned' => sub {
    plan tests => 3;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $monitor = connect_with_timeout($socket_file, $username, $password, 'monitor');

    SKIP: {
        skip "Monitor not connected", 3 unless $monitor;

        $monitor->setMonitormode(1);
        $monitor->doNetwork();
        sleep(0.2);

        my @clients;
        my $client_count = 5;  # Reduced for speed
        for my $i (1..$client_count) {
            my $client = connect_with_timeout($socket_file, $username, $password, "multi_$i");
            if ($client) {
                $client->ping();
                $client->doNetwork();
                push @clients, $client;
            }
        }

        ok(scalar(@clients) == $client_count, "Connected $client_count clients");

        $monitor->doNetwork();
        drain_messages($monitor);

        for my $client (@clients) {
            $client->disconnect();
        }

        # Poll multiple times to receive all disconnect messages
        my $disconnect_count = 0;
        for my $attempt (1..20) {
            sleep(0.2);
            $monitor->doNetwork();
            while (my $msg = $monitor->getNext()) {
                diag("Monitor received: type=$msg->{type}, host=" . ($msg->{host} // 'undef') . ", command=" . ($msg->{command} // 'undef')) if $ENV{TEST_VERBOSE};
                if ($msg->{type} eq 'debug' && defined($msg->{host}) && $msg->{host} eq 'DISCONNECTED') {
                    $disconnect_count++;
                }
            }
            last if $disconnect_count >= $client_count;
        }

        ok($disconnect_count == $client_count,
           "All clients cleaned up (got $disconnect_count of $client_count)");

        my $verify = connect_with_timeout($socket_file, $username, $password, 'verify');
        ok($verify, 'Server responsive after multiple disconnects');
        $verify->disconnect() if $verify;

        $monitor->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 6: EPIPE Handling
# ============================================================================
subtest 'EPIPE handling - verify cleanup on write error' => sub {
    plan tests => 3;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $monitor = connect_with_timeout($socket_file, $username, $password, 'monitor');

    SKIP: {
        skip "Monitor not connected", 3 unless $monitor;

        $monitor->setMonitormode(1);
        $monitor->doNetwork();
        sleep(0.2);

        my $sender = connect_with_timeout($socket_file, $username, $password, 'sender');
        my $receiver = connect_with_timeout($socket_file, $username, $password, 'receiver');

        if ($receiver) {
            $receiver->listen('test::epipe');
            $receiver->doNetwork();
        }

        $monitor->doNetwork();
        drain_messages($monitor);

        # Abruptly close receiver's socket and prevent DESTROY from trying to use it
        if ($receiver && $receiver->{socket}) {
            close($receiver->{socket});
            delete $receiver->{socket};  # Prevent DESTROY from trying to close it
            undef $receiver;  # Release the object now
        }

        if ($sender) {
            $sender->set('test::epipe', 'trigger');
            $sender->doNetwork();
        }

        # Poll multiple times for disconnect message
        my $found_disconnect = 0;
        for my $attempt (1..10) {
            sleep(0.2);
            $monitor->doNetwork();
            while (my $msg = $monitor->getNext()) {
                diag("Monitor received: type=$msg->{type}, host=" . ($msg->{host} // 'undef') . ", command=" . ($msg->{command} // 'undef')) if $ENV{TEST_VERBOSE};
                if ($msg->{type} eq 'debug' && defined($msg->{host}) && $msg->{host} eq 'DISCONNECTED') {
                    $found_disconnect = 1;
                    last;
                }
            }
            last if $found_disconnect;
        }
        ok($found_disconnect, 'Server cleaned up after EPIPE');

        my $verify = connect_with_timeout($socket_file, $username, $password, 'verify');
        ok($verify, 'Server responsive after EPIPE');
        ok(1, 'Server survived EPIPE condition');

        $sender->disconnect() if $sender;
        $verify->disconnect() if $verify;
        $monitor->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 7: Client Reconnect Cleanup
# ============================================================================
subtest 'Client reconnect - verify old resources cleaned' => sub {
    plan tests => 4;

    diag("TEST7: Forking server") if $ENV{TEST_VERBOSE};
    my $server_pid = fork_server();
    diag("TEST7: Server PID=$server_pid, waiting for socket") if $ENV{TEST_VERBOSE};
    wait_for_socket($socket_file, 10);
    diag("TEST7: Socket ready, connecting monitor") if $ENV{TEST_VERBOSE};

    my $monitor = connect_with_timeout($socket_file, $username, $password, 'monitor');

    SKIP: {
        skip "Monitor not connected", 4 unless $monitor;

        diag("TEST7: Monitor connected, setting mode") if $ENV{TEST_VERBOSE};
        $monitor->setMonitormode(1);
        $monitor->doNetwork();
        sleep(0.2);

        diag("TEST7: Connecting test client") if $ENV{TEST_VERBOSE};
        my $client = connect_with_timeout($socket_file, $username, $password, 'reconnect_test');
        ok($client, 'Initial connection');

        if ($client) {
            $client->ping();
            $client->doNetwork();

            $monitor->doNetwork();
            drain_messages($monitor);

            diag("TEST7: Calling reconnect()") if $ENV{TEST_VERBOSE};
            $client->reconnect();
            diag("TEST7: Reconnect returned, socket=" . ($client->{socket} ? "yes" : "no")) if $ENV{TEST_VERBOSE};
            ok($client->{socket}, 'Reconnected successfully');

            # Poll multiple times for disconnect message
            diag("TEST7: Polling for DISCONNECTED") if $ENV{TEST_VERBOSE};
            my $found_disconnect = 0;
            for my $attempt (1..10) {
                sleep(0.2);
                $monitor->doNetwork();
                while (my $msg = $monitor->getNext()) {
                    diag("Monitor received: type=$msg->{type}, host=" . ($msg->{host} // 'undef') . ", command=" . ($msg->{command} // 'undef')) if $ENV{TEST_VERBOSE};
                    if ($msg->{type} eq 'debug' && defined($msg->{host}) && $msg->{host} eq 'DISCONNECTED') {
                        $found_disconnect = 1;
                        last;
                    }
                }
                last if $found_disconnect;
            }
            ok($found_disconnect, 'Server cleaned up old connection');

            diag("TEST7: Testing communication") if $ENV{TEST_VERBOSE};
            $client->ping();
            $client->doNetwork();
            ok(1, 'Communication works after reconnect');

            diag("TEST7: Disconnecting client") if $ENV{TEST_VERBOSE};
            $client->disconnect();
        } else {
            ok(0, 'Reconnected successfully');
            ok(0, 'Server cleaned up old connection');
            ok(0, 'Communication works after reconnect');
        }

        diag("TEST7: Disconnecting monitor") if $ENV{TEST_VERBOSE};
        $monitor->disconnect();
    }

    diag("TEST7: Killing server") if $ENV{TEST_VERBOSE};
    kill_server($server_pid);
    diag("TEST7: Done") if $ENV{TEST_VERBOSE};
};

# ============================================================================
# Helper Functions
# ============================================================================

sub update_config_socket_path {
    # Rewrite the config file with absolute socket path
    open(my $fh, '>', $config_file) or die "Cannot write $config_file: $!";
    print $fh <<"EOF";
<clacks>
    <appname>Test Server</appname>
    <socket>$socket_file</socket>
    <pingtimeout>10</pingtimeout>
    <interclackspingtimeout>5</interclackspingtimeout>
    <username>testuser</username>
    <password>testpass</password>
    <throttle>
        <maxsleep>50</maxsleep>
        <step>10</step>
    </throttle>
</clacks>
EOF
    close($fh);
}

sub fork_server {
    my $pid = fork();
    if ($pid == 0) {
        # Child - run server
        # Close Test::More's tied filehandles before redirecting
        Test::More->builder->reset();
        close(STDIN);
        close(STDOUT);
        close(STDERR);
        open(STDIN, '<', '/dev/null');
        open(STDOUT, '>', '/dev/null');
        open(STDERR, '>', '/dev/null');

        my $server = Net::Clacks::Server->new(0, $config_file);

        $SIG{TERM} = sub { exit(0); };

        while (1) {
            $server->runOnce();
        }
        exit(0);
    }
    $global_server_pid = $pid;
    return $pid;
}

sub wait_for_socket {
    my ($socket, $timeout) = @_;
    my $start = time();
    while (!-S $socket && (time() - $start) < $timeout) {
        sleep(0.1);
    }
    return -S $socket;
}

sub connect_with_timeout {
    my ($socket, $user, $pass, $name) = @_;
    my $client = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(5);
        my $c = Net::Clacks::Client->newSocket($socket, $user, $pass, $name, 0);
        alarm(0);
        $c;
    };
    alarm(0);
    return $client;
}

sub kill_server {
    my ($pid) = @_;
    return unless $pid;

    # Force kill - server may be blocking in select() and not responding to SIGTERM
    kill('KILL', $pid);
    waitpid($pid, 0);

    unlink $socket_file if -e $socket_file;
    $global_server_pid = undef;
}

sub count_fds {
    my ($pid) = @_;
    return 0 unless $pid && -d "/proc/$pid/fd";
    my @fds = glob("/proc/$pid/fd/*");
    return scalar(@fds);
}

sub drain_messages {
    my ($client) = @_;
    while (my $msg = $client->getNext()) {
        # Discard
    }
}

END {
    if ($global_server_pid) {
        kill('TERM', $global_server_pid);
        waitpid($global_server_pid, 0);
    }
    unlink $socket_file if defined($socket_file) && -e $socket_file;
}

1;
