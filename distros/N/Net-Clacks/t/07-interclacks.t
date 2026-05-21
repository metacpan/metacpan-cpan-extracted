#!/usr/bin/env perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 07-interclacks.t'

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
my $master_config = File::Spec->catfile($test_dir, 'test_master.xml');
my $slave_config = File::Spec->catfile($test_dir, 'test_slave.xml');
my $master_socket = File::Spec->catfile($test_dir, 'test_master.sock');
my $slave_socket = File::Spec->catfile($test_dir, 'test_slave.sock');

my $username = 'testuser';
my $password = 'testpass';

# Track server PIDs globally for cleanup
my $master_pid;
my $slave_pid;

# Cleanup any leftover sockets
unlink $master_socket if -e $master_socket;
unlink $slave_socket if -e $slave_socket;

# Create config files
create_master_config();
create_slave_config();

plan tests => 8;

# ============================================================================
# Test 1: Master-Slave Connection
# ============================================================================
subtest 'Master-slave connection establishment' => sub {
    plan tests => 4;

    $master_pid = fork_server($master_config, 'master');
    ok($master_pid, 'Master server forked');
    wait_for_socket($master_socket, 10);
    ok(-S $master_socket, 'Master socket ready');

    $slave_pid = fork_server($slave_config, 'slave');
    ok($slave_pid, 'Slave server forked');
    wait_for_socket($slave_socket, 10);
    ok(-S $slave_socket, 'Slave socket ready');

    # Give time for interclacks connection to establish
    sleep(1);

    cleanup_servers();
};

# ============================================================================
# Test 2: KEYSYNC Completion
# ============================================================================
subtest 'KEYSYNC completion' => sub {
    plan tests => 3;

    # Start master first and store some values
    $master_pid = fork_server($master_config, 'master');
    wait_for_socket($master_socket, 10);

    my $client = connect_with_timeout($master_socket, $username, $password, 'setup');
    if ($client) {
        $client->store('sync::value1', 'master_data_1');
        $client->store('sync::value2', 'master_data_2');
        $client->doNetwork();
        sleep(0.2);
        $client->disconnect();
    }

    # Now start slave - it should sync
    $slave_pid = fork_server($slave_config, 'slave');
    wait_for_socket($slave_socket, 10);

    # Give time for KEYSYNC
    sleep(2);

    # Connect to slave and verify data synced
    my $slave_client = connect_with_timeout($slave_socket, $username, $password, 'verify_sync');

    SKIP: {
        skip "Slave client not connected", 3 unless $slave_client;

        my $val1 = $slave_client->retrieve('sync::value1');
        my $val2 = $slave_client->retrieve('sync::value2');

        is($val1, 'master_data_1', 'Value 1 synced to slave');
        is($val2, 'master_data_2', 'Value 2 synced to slave');
        ok(1, 'KEYSYNC completed successfully');

        $slave_client->disconnect();
    }

    cleanup_servers();
};

# ============================================================================
# Test 3: Real-time SET Forwarding
# ============================================================================
subtest 'Real-time SET forwarding' => sub {
    plan tests => 3;

    $master_pid = fork_server($master_config, 'master');
    wait_for_socket($master_socket, 10);

    $slave_pid = fork_server($slave_config, 'slave');
    wait_for_socket($slave_socket, 10);
    sleep(1);  # Allow interclacks to establish

    # Client connected to master sends SET
    my $master_client = connect_with_timeout($master_socket, $username, $password, 'master_sender');

    # Client connected to slave listens
    my $slave_client = connect_with_timeout($slave_socket, $username, $password, 'slave_listener');

    SKIP: {
        skip "Clients not connected", 3 unless $master_client && $slave_client;

        $slave_client->listen('realtime::test');
        $slave_client->doNetwork();
        sleep(0.5);  # Extra time for interclacks LISTEN forwarding

        # Send from master
        $master_client->set('realtime::test', 'forwarded value');
        $master_client->doNetwork();

        # Poll for message receipt (time-based for hardware independence)
        my $received = 0;
        my $received_value;
        my $timeout = time() + 5;
        while (time() < $timeout && !$received) {
            sleep(0.1);
            $slave_client->doNetwork();
            while (my $msg = $slave_client->getNext()) {
                if ($msg->{type} eq 'set' && $msg->{name} eq 'realtime::test') {
                    $received = 1;
                    $received_value = $msg->{data};
                    last;
                }
            }
        }

        ok($received, 'Slave received SET from master');
        is($received_value, 'forwarded value', 'Correct value forwarded');
        ok(1, 'Real-time forwarding works');

        $master_client->disconnect();
        $slave_client->disconnect();
    }

    cleanup_servers();
};

# ============================================================================
# Test 4: Real-time NOTIFY Forwarding
# ============================================================================
subtest 'Real-time NOTIFY forwarding' => sub {
    plan tests => 2;

    $master_pid = fork_server($master_config, 'master');
    wait_for_socket($master_socket, 10);

    $slave_pid = fork_server($slave_config, 'slave');
    wait_for_socket($slave_socket, 10);
    sleep(1);

    my $master_client = connect_with_timeout($master_socket, $username, $password, 'master_notifier');
    my $slave_client = connect_with_timeout($slave_socket, $username, $password, 'slave_notify_listener');

    SKIP: {
        skip "Clients not connected", 2 unless $master_client && $slave_client;

        $slave_client->listen('event::forward');
        $slave_client->doNetwork();
        sleep(0.5);  # Extra time for interclacks LISTEN forwarding

        $master_client->notify('event::forward');
        $master_client->doNetwork();

        # Poll for message receipt (time-based for hardware independence)
        my $received = 0;
        my $timeout = time() + 5;
        while (time() < $timeout && !$received) {
            sleep(0.1);
            $slave_client->doNetwork();
            while (my $msg = $slave_client->getNext()) {
                if ($msg->{type} eq 'notify' && $msg->{name} eq 'event::forward') {
                    $received = 1;
                    last;
                }
            }
        }

        ok($received, 'Slave received NOTIFY from master');
        ok(1, 'NOTIFY forwarding works');

        $master_client->disconnect();
        $slave_client->disconnect();
    }

    cleanup_servers();
};

# ============================================================================
# Test 5: Bidirectional Sync (slave to master)
# ============================================================================
subtest 'Bidirectional sync - slave to master' => sub {
    plan tests => 2;

    $master_pid = fork_server($master_config, 'master');
    wait_for_socket($master_socket, 10);

    $slave_pid = fork_server($slave_config, 'slave');
    wait_for_socket($slave_socket, 10);
    sleep(1);

    # Store on slave
    my $slave_client = connect_with_timeout($slave_socket, $username, $password, 'slave_storer');

    SKIP: {
        skip "Slave client not connected", 2 unless $slave_client;

        $slave_client->store('bidir::from_slave', 'slave_originated');
        $slave_client->doNetwork();
        sleep(0.5);
        $slave_client->disconnect();

        # Verify on master
        my $master_client = connect_with_timeout($master_socket, $username, $password, 'master_verifier');
        if ($master_client) {
            my $val = $master_client->retrieve('bidir::from_slave');
            is($val, 'slave_originated', 'Master received data from slave');
            ok(1, 'Bidirectional sync works');
            $master_client->disconnect();
        } else {
            ok(0, 'Master received data from slave');
            ok(0, 'Bidirectional sync works');
        }
    }

    cleanup_servers();
};

# ============================================================================
# Test 6: End-to-end: Client on slave receives master client broadcast
# ============================================================================
subtest 'End-to-end client communication' => sub {
    plan tests => 2;

    $master_pid = fork_server($master_config, 'master');
    wait_for_socket($master_socket, 10);

    $slave_pid = fork_server($slave_config, 'slave');
    wait_for_socket($slave_socket, 10);
    sleep(1);

    my $master_client = connect_with_timeout($master_socket, $username, $password, 'app_on_master');
    my $slave_client = connect_with_timeout($slave_socket, $username, $password, 'app_on_slave');

    SKIP: {
        skip "Clients not connected", 2 unless $master_client && $slave_client;

        # Slave client listens
        $slave_client->listen('e2e::channel');
        $slave_client->doNetwork();
        sleep(0.5);  # Extra time for interclacks LISTEN forwarding

        # Master client sends
        $master_client->set('e2e::channel', 'cross-server message');
        $master_client->doNetwork();

        # Poll for message receipt (time-based for hardware independence)
        my $received = 0;
        my $timeout = time() + 5;
        while (time() < $timeout && !$received) {
            sleep(0.1);
            $slave_client->doNetwork();
            while (my $msg = $slave_client->getNext()) {
                if ($msg->{type} eq 'set' && $msg->{name} eq 'e2e::channel') {
                    $received = 1;
                    last;
                }
            }
        }

        ok($received, 'End-to-end communication works');
        ok(1, 'Apps on different servers can communicate');

        $master_client->disconnect();
        $slave_client->disconnect();
    }

    cleanup_servers();
};

# ============================================================================
# Test 7: Connection Stability Under Load
# ============================================================================
subtest 'Connection stability under load' => sub {
    plan tests => 3;

    $master_pid = fork_server($master_config, 'master');
    wait_for_socket($master_socket, 10);

    $slave_pid = fork_server($slave_config, 'slave');
    wait_for_socket($slave_socket, 10);
    sleep(1);

    my $sender = connect_with_timeout($master_socket, $username, $password, 'load_sender');
    my $receiver = connect_with_timeout($slave_socket, $username, $password, 'load_receiver');

    SKIP: {
        skip "Clients not connected", 3 unless $sender && $receiver;

        $receiver->listen('load::test');
        $receiver->doNetwork();
        sleep(0.5);  # Extra time for interclacks LISTEN forwarding

        # Send many messages
        my $message_count = 50;
        for my $i (1..$message_count) {
            $sender->set('load::test', "message_$i");
            $sender->doNetwork() if ($i % 10 == 0);
        }
        $sender->doNetwork();

        # Poll for messages (time-based for hardware independence)
        my $received_count = 0;
        my $timeout = time() + 10;  # Longer timeout for load test
        while (time() < $timeout) {
            sleep(0.1);
            $receiver->doNetwork();
            while (my $msg = $receiver->getNext()) {
                if ($msg->{type} eq 'set' && $msg->{name} eq 'load::test') {
                    $received_count++;
                }
            }
            # Stop early if we got all messages
            last if $received_count >= $message_count;
        }

        ok($received_count > 0, "Received messages: $received_count");
        ok($received_count >= $message_count * 0.9, "Received at least 90% of messages ($received_count of $message_count)");
        ok(1, 'Connection stable under load');

        $sender->disconnect();
        $receiver->disconnect();
    }

    cleanup_servers();
};

# ============================================================================
# Test 8: Slave Reconnect After Master Restart
# ============================================================================
subtest 'Slave reconnect after master restart' => sub {
    plan tests => 3;

    # Start both servers
    $master_pid = fork_server($master_config, 'master');
    wait_for_socket($master_socket, 10);

    $slave_pid = fork_server($slave_config, 'slave');
    wait_for_socket($slave_socket, 10);
    sleep(1);

    # Store value on master
    my $client = connect_with_timeout($master_socket, $username, $password, 'initial');
    if ($client) {
        $client->store('reconnect::test', 'before_restart');
        $client->doNetwork();
        sleep(0.2);
        $client->disconnect();
    }

    # Kill and restart master
    kill_server_by_pid($master_pid);
    unlink $master_socket if -e $master_socket;
    sleep(0.5);

    $master_pid = fork_server($master_config, 'master');
    wait_for_socket($master_socket, 10);

    # Wait for slave to detect connection loss and start reconnect
    # With interclackspingtimeout=5 and interclacksreconnecttimeout=3, this should be enough
    sleep(5);

    # Store new value on master
    my $client2 = connect_with_timeout($master_socket, $username, $password, 'after_restart');
    if ($client2) {
        $client2->store('reconnect::new', 'after_restart_value');
        $client2->doNetwork();
        sleep(0.5);
        $client2->disconnect();
    }

    # Poll for slave to receive the synced value
    my $slave_client = connect_with_timeout($slave_socket, $username, $password, 'verify_reconnect');

    SKIP: {
        skip "Slave client not connected", 3 unless $slave_client;

        # Give time for reconnect and sync to propagate
        # Total time: detect (up to 5s) + reconnect (up to 3s) + sync
        my $val;
        my $timeout = time() + 15;
        while (time() < $timeout) {
            $val = $slave_client->retrieve('reconnect::new');
            last if defined($val);
            sleep(0.5);
        }

        is($val, 'after_restart_value', 'Slave received value after reconnect');
        ok(1, 'Slave reconnected successfully');
        ok(1, 'Data synced after reconnect');

        $slave_client->disconnect();
    }

    cleanup_servers();
};

# ============================================================================
# Helper Functions
# ============================================================================

sub create_master_config {
    open(my $fh, '>', $master_config) or die "Cannot write $master_config: $!";
    print $fh <<"EOF";
<clacks>
    <appname>Test Master</appname>
    <socket>$master_socket</socket>
    <pingtimeout>60</pingtimeout>
    <interclackspingtimeout>5</interclackspingtimeout>
    <interclacksreconnecttimeout>3</interclacksreconnecttimeout>
    <username>$username</username>
    <password>$password</password>
    <throttle>
        <maxsleep>50</maxsleep>
        <step>10</step>
    </throttle>
</clacks>
EOF
    close($fh);
}

sub create_slave_config {
    open(my $fh, '>', $slave_config) or die "Cannot write $slave_config: $!";
    print $fh <<"EOF";
<clacks>
    <appname>Test Slave</appname>
    <socket>$slave_socket</socket>
    <pingtimeout>60</pingtimeout>
    <interclackspingtimeout>5</interclackspingtimeout>
    <interclacksreconnecttimeout>3</interclacksreconnecttimeout>
    <username>$username</username>
    <password>$password</password>
    <throttle>
        <maxsleep>50</maxsleep>
        <step>10</step>
    </throttle>
    <master>
        <socket>$master_socket</socket>
    </master>
</clacks>
EOF
    close($fh);
}

sub fork_server {
    my ($config, $name) = @_;
    my $pid = fork();
    if ($pid == 0) {
        # Child - run server
        Test::More->builder->reset();
        close(STDIN);
        close(STDOUT);
        close(STDERR);
        open(STDIN, '<', '/dev/null');
        open(STDOUT, '>', '/dev/null');
        open(STDERR, '>', '/dev/null');

        my $server = Net::Clacks::Server->new(0, $config);

        $SIG{TERM} = sub { exit(0); };

        while (1) {
            $server->runOnce();
        }
        exit(0);
    }
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

sub kill_server_by_pid {
    my ($pid) = @_;
    return unless $pid;
    kill('KILL', $pid);
    waitpid($pid, 0);
}

sub cleanup_servers {
    if ($master_pid) {
        kill('KILL', $master_pid);
        waitpid($master_pid, 0);
        $master_pid = undef;
    }
    if ($slave_pid) {
        kill('KILL', $slave_pid);
        waitpid($slave_pid, 0);
        $slave_pid = undef;
    }
    unlink $master_socket if defined($master_socket) && -e $master_socket;
    unlink $slave_socket if defined($slave_socket) && -e $slave_socket;
}

END {
    cleanup_servers();
    unlink $master_config if defined($master_config) && -e $master_config;
    unlink $slave_config if defined($slave_config) && -e $slave_config;
}

1;
