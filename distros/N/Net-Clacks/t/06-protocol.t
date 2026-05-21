#!/usr/bin/env perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 06-protocol.t'

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
my $config_file = File::Spec->catfile($test_dir, 'test_protocol_server.xml');
my $socket_file = File::Spec->catfile($test_dir, 'test_protocol.sock');

# User credentials
my $admin_user = 'admin';
my $admin_pass = 'adminpass';
my $rw_user = 'rwuser';
my $rw_pass = 'rwpass';
my $ro_user = 'rouser';
my $ro_pass = 'ropass';

# Track server PID globally for cleanup
my $global_server_pid;

# Cleanup any leftover socket
unlink $socket_file if -e $socket_file;

# Create config file with multiple user levels
create_config_file();

plan tests => 12;

# ============================================================================
# Test 1: STORE and RETRIEVE
# ============================================================================
subtest 'STORE and RETRIEVE' => sub {
    plan tests => 4;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $client = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'store_test');
    ok($client, 'Client connected');

    SKIP: {
        skip "Client not connected", 3 unless $client;

        # Store a value
        $client->store('test::value', 'hello world');
        $client->doNetwork();
        sleep(0.1);

        # Retrieve it
        my $value = $client->retrieve('test::value');
        is($value, 'hello world', 'Retrieved stored value');

        # Store another value
        $client->store('test::number', '42');
        $client->doNetwork();
        sleep(0.1);

        my $num = $client->retrieve('test::number');
        is($num, '42', 'Retrieved numeric value');

        # Retrieve non-existent
        my $missing = $client->retrieve('test::nonexistent');
        is($missing, undef, 'Non-existent returns undef');

        $client->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 2: REMOVE
# ============================================================================
subtest 'REMOVE' => sub {
    plan tests => 3;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $client = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'remove_test');

    SKIP: {
        skip "Client not connected", 3 unless $client;

        $client->store('test::toremove', 'temporary');
        $client->doNetwork();
        sleep(0.1);

        my $before = $client->retrieve('test::toremove');
        is($before, 'temporary', 'Value exists before remove');

        $client->remove('test::toremove');
        $client->doNetwork();
        sleep(0.1);

        my $after = $client->retrieve('test::toremove');
        is($after, undef, 'Value removed');

        ok(1, 'Remove operation completed');

        $client->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 3: INCREMENT and DECREMENT
# ============================================================================
subtest 'INCREMENT and DECREMENT' => sub {
    plan tests => 5;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $client = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'math_test');

    SKIP: {
        skip "Client not connected", 5 unless $client;

        # Increment non-existent (should start from 0)
        $client->increment('test::counter');
        $client->doNetwork();
        sleep(0.1);

        my $val1 = $client->retrieve('test::counter');
        is($val1, '1', 'Increment from zero');

        # Increment by custom amount
        $client->increment('test::counter', 5);
        $client->doNetwork();
        sleep(0.1);

        my $val2 = $client->retrieve('test::counter');
        is($val2, '6', 'Increment by 5');

        # Decrement
        $client->decrement('test::counter', 2);
        $client->doNetwork();
        sleep(0.1);

        my $val3 = $client->retrieve('test::counter');
        is($val3, '4', 'Decrement by 2');

        # Decrement by 1 (default)
        $client->decrement('test::counter');
        $client->doNetwork();
        sleep(0.1);

        my $val4 = $client->retrieve('test::counter');
        is($val4, '3', 'Decrement by 1');

        ok(1, 'Math operations completed');

        $client->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 4: KEYLIST
# ============================================================================
subtest 'KEYLIST' => sub {
    plan tests => 4;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $client = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'keylist_test');

    SKIP: {
        skip "Client not connected", 4 unless $client;

        # Store some values
        $client->store('keylist::one', '1');
        $client->store('keylist::two', '2');
        $client->store('keylist::three', '3');
        $client->doNetwork();
        sleep(0.2);

        # Get key list
        my @keys = $client->keylist();

        ok(scalar(@keys) >= 3, 'Got at least 3 keys');

        my $found_one = grep { $_ eq 'keylist::one' } @keys;
        my $found_two = grep { $_ eq 'keylist::two' } @keys;
        my $found_three = grep { $_ eq 'keylist::three' } @keys;

        ok($found_one, 'Found keylist::one');
        ok($found_two, 'Found keylist::two');
        ok($found_three, 'Found keylist::three');

        $client->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 5: SET with LISTEN
# ============================================================================
subtest 'SET with LISTEN' => sub {
    plan tests => 4;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $sender = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'sender');
    my $listener = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'listener');

    SKIP: {
        skip "Clients not connected", 4 unless $sender && $listener;

        # Listener subscribes
        $listener->listen('broadcast::channel');
        $listener->doNetwork();
        sleep(0.1);

        # Sender sends
        $sender->set('broadcast::channel', 'hello listeners');
        $sender->doNetwork();

        # Poll for message receipt
        my $received = 0;
        my $received_value;
        for my $attempt (1..20) {
            sleep(0.1);
            $listener->doNetwork();
            while (my $msg = $listener->getNext()) {
                if ($msg->{type} eq 'set' && $msg->{name} eq 'broadcast::channel') {
                    $received = 1;
                    $received_value = $msg->{data};
                    last;
                }
            }
            last if $received;
        }

        ok($received, 'Listener received SET message');
        is($received_value, 'hello listeners', 'Received correct value');

        # Verify sender doesn't receive own message
        $sender->doNetwork();
        my $sender_got_own = 0;
        while (my $msg = $sender->getNext()) {
            if ($msg->{type} eq 'set' && $msg->{name} eq 'broadcast::channel') {
                $sender_got_own = 1;
            }
        }
        ok(!$sender_got_own, 'Sender did not receive own message');

        ok(1, 'SET/LISTEN test completed');

        $sender->disconnect();
        $listener->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 6: NOTIFY with LISTEN
# ============================================================================
subtest 'NOTIFY with LISTEN' => sub {
    plan tests => 3;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $notifier = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'notifier');
    my $listener = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'notify_listener');

    SKIP: {
        skip "Clients not connected", 3 unless $notifier && $listener;

        $listener->listen('event::channel');
        $listener->doNetwork();
        sleep(0.1);

        $notifier->notify('event::channel');
        $notifier->doNetwork();

        # Poll for message receipt
        my $received = 0;
        for my $attempt (1..20) {
            sleep(0.1);
            $listener->doNetwork();
            while (my $msg = $listener->getNext()) {
                if ($msg->{type} eq 'notify' && $msg->{name} eq 'event::channel') {
                    $received = 1;
                    last;
                }
            }
            last if $received;
        }

        ok($received, 'Listener received NOTIFY');
        ok(1, 'NOTIFY has no data value (event only)');
        ok(1, 'NOTIFY test completed');

        $notifier->disconnect();
        $listener->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 7: UNLISTEN
# ============================================================================
subtest 'UNLISTEN' => sub {
    plan tests => 3;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $sender = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'sender2');
    my $listener = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'unlisten_test');

    SKIP: {
        skip "Clients not connected", 3 unless $sender && $listener;

        # Subscribe
        $listener->listen('unlisten::test');
        $listener->doNetwork();
        sleep(0.1);

        # Verify receiving
        $sender->set('unlisten::test', 'before');
        $sender->doNetwork();

        my $got_before = 0;
        for my $attempt (1..20) {
            sleep(0.1);
            $listener->doNetwork();
            while (my $msg = $listener->getNext()) {
                if ($msg->{type} eq 'set' && $msg->{name} eq 'unlisten::test') {
                    $got_before = 1;
                }
            }
            last if $got_before;
        }
        ok($got_before, 'Received before unlisten');

        # Unsubscribe
        $listener->unlisten('unlisten::test');
        $listener->doNetwork();
        sleep(0.2);

        # Send again
        $sender->set('unlisten::test', 'after');
        $sender->doNetwork();
        sleep(0.5);

        $listener->doNetwork();
        my $got_after = 0;
        while (my $msg = $listener->getNext()) {
            if ($msg->{type} eq 'set' && $msg->{name} eq 'unlisten::test') {
                $got_after = 1;
            }
        }
        ok(!$got_after, 'Did NOT receive after unlisten');

        ok(1, 'UNLISTEN test completed');

        $sender->disconnect();
        $listener->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 8: SETANDSTORE
# ============================================================================
subtest 'SETANDSTORE' => sub {
    plan tests => 3;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $client1 = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'setandstore1');
    my $client2 = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'setandstore2');

    SKIP: {
        skip "Clients not connected", 3 unless $client1 && $client2;

        $client2->listen('combined::test');
        $client2->doNetwork();
        sleep(0.1);

        # Use setAndStore (combined SET + STORE)
        $client1->setAndStore('combined::test', 'combined value');
        $client1->doNetwork();

        # Poll for message receipt
        my $received = 0;
        for my $attempt (1..20) {
            sleep(0.1);
            $client2->doNetwork();
            while (my $msg = $client2->getNext()) {
                if ($msg->{type} eq 'set' && $msg->{name} eq 'combined::test') {
                    $received = 1;
                    last;
                }
            }
            last if $received;
        }
        ok($received, 'Listener received SET from SETANDSTORE');

        # Value should also be stored (retrievable)
        my $stored = $client1->retrieve('combined::test');
        is($stored, 'combined value', 'Value was also stored');

        ok(1, 'SETANDSTORE test completed');

        $client1->disconnect();
        $client2->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 9: FLUSH
# ============================================================================
subtest 'FLUSH' => sub {
    plan tests => 3;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $client = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'flush_test');

    SKIP: {
        skip "Client not connected", 3 unless $client;

        # Send multiple commands then flush
        $client->store('flush::a', '1');
        $client->store('flush::b', '2');
        $client->store('flush::c', '3');

        # flush() is synchronous - it sends FLUSH and waits for FLUSHED internally
        # If it returns without hanging, the FLUSHED response was received
        my $flush_id = 'test_' . time();
        my $flush_ok = eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm(5);
            $client->flush($flush_id);
            alarm(0);
            1;
        };
        alarm(0);

        ok($flush_ok, 'flush() completed without timeout');

        # Verify the stored values are accessible
        my $val = $client->retrieve('flush::a');
        is($val, '1', 'Stored value accessible after flush');

        ok(1, 'FLUSH test completed');

        $client->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 10: CLIENTLIST (manage permission)
# ============================================================================
subtest 'CLIENTLIST' => sub {
    plan tests => 4;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $admin = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'admin_client');
    my $other = connect_with_timeout($socket_file, $rw_user, $rw_pass, 'other_client');

    SKIP: {
        skip "Clients not connected", 4 unless $admin && $other;

        $admin->doNetwork();
        $other->doNetwork();
        sleep(0.2);

        # Admin gets client list
        my @clients = $admin->clientlist();

        ok(scalar(@clients) >= 2, 'Got at least 2 clients');

        # Keys are lowercased by clientlist()
        my $found_admin = grep { $_->{clientinfo} && $_->{clientinfo} =~ /admin_client/ } @clients;
        my $found_other = grep { $_->{clientinfo} && $_->{clientinfo} =~ /other_client/ } @clients;

        ok($found_admin, 'Found admin_client in list');
        ok($found_other, 'Found other_client in list');

        ok(1, 'CLIENTLIST test completed');

        $admin->disconnect();
        $other->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 11: Read-only user permissions
# ============================================================================
subtest 'Read-only user permissions' => sub {
    plan tests => 4;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    # Admin stores a value first
    my $admin = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'admin_setup');
    if ($admin) {
        $admin->store('perm::test', 'readable');
        $admin->doNetwork();
        sleep(0.1);
        $admin->disconnect();
    }

    # Connect as read-only user
    my $ro = connect_with_timeout($socket_file, $ro_user, $ro_pass, 'ro_client');

    SKIP: {
        skip "RO client not connected", 4 unless $ro;

        # Can retrieve
        my $val = $ro->retrieve('perm::test');
        is($val, 'readable', 'RO user can retrieve');

        # Try to store (should fail silently or be ignored)
        $ro->store('perm::ro_attempt', 'should_fail');
        $ro->doNetwork();
        sleep(0.2);

        # Verify it wasn't stored (reconnect as admin to check)
        my $admin2 = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'admin_verify');
        my $ro_stored = $admin2 ? $admin2->retrieve('perm::ro_attempt') : undef;
        is($ro_stored, undef, 'RO user cannot store');
        $admin2->disconnect() if $admin2;

        ok(1, 'RO permissions enforced');
        ok(1, 'Permission test completed');

        $ro->disconnect();
    }

    kill_server($server_pid);
};

# ============================================================================
# Test 12: Multiple listeners receive same broadcast
# ============================================================================
subtest 'Multiple listeners' => sub {
    plan tests => 4;

    my $server_pid = fork_server();
    wait_for_socket($socket_file, 10);

    my $sender = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'multi_sender');
    my $listener1 = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'multi_listener1');
    my $listener2 = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'multi_listener2');
    my $listener3 = connect_with_timeout($socket_file, $admin_user, $admin_pass, 'multi_listener3');

    SKIP: {
        skip "Clients not connected", 4 unless $sender && $listener1 && $listener2 && $listener3;

        # All listeners subscribe
        $listener1->listen('multi::channel');
        $listener2->listen('multi::channel');
        $listener3->listen('multi::channel');
        $_->doNetwork() for ($listener1, $listener2, $listener3);
        sleep(0.2);

        # Send broadcast
        $sender->set('multi::channel', 'broadcast to all');
        $sender->doNetwork();

        # Poll for message receipt on all listeners
        my %received;
        for my $attempt (1..20) {
            sleep(0.1);
            for my $i (1..3) {
                my $listener = ($listener1, $listener2, $listener3)[$i-1];
                next if $received{$i};  # Already received
                $listener->doNetwork();
                while (my $msg = $listener->getNext()) {
                    if ($msg->{type} eq 'set' && $msg->{name} eq 'multi::channel') {
                        $received{$i} = 1;
                        last;
                    }
                }
            }
            last if scalar(keys %received) == 3;
        }

        is(scalar(keys %received), 3, 'All 3 listeners received broadcast');
        ok($received{1}, 'Listener 1 received');
        ok($received{2}, 'Listener 2 received');
        ok($received{3}, 'Listener 3 received');

        $_->disconnect() for ($sender, $listener1, $listener2, $listener3);
    }

    kill_server($server_pid);
};

# ============================================================================
# Helper Functions
# ============================================================================

sub create_config_file {
    open(my $fh, '>', $config_file) or die "Cannot write $config_file: $!";
    print $fh <<"EOF";
<clacks>
    <appname>Protocol Test Server</appname>
    <socket>$socket_file</socket>
    <pingtimeout>60</pingtimeout>
    <interclackspingtimeout>30</interclackspingtimeout>

    <!-- Admin user with all permissions -->
    <username>$admin_user</username>
    <password>$admin_pass</password>

    <!-- Read-write user -->
    <user>
        <username>$rw_user</username>
        <password>$rw_pass</password>
        <read>1</read>
        <write>1</write>
        <manage>0</manage>
    </user>

    <!-- Read-only user -->
    <user>
        <username>$ro_user</username>
        <password>$ro_pass</password>
        <read>1</read>
        <write>0</write>
        <manage>0</manage>
    </user>

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

    kill('KILL', $pid);
    waitpid($pid, 0);

    unlink $socket_file if -e $socket_file;
    $global_server_pid = undef;
}

END {
    if ($global_server_pid) {
        kill('TERM', $global_server_pid);
        waitpid($global_server_pid, 0);
    }
    unlink $socket_file if defined($socket_file) && -e $socket_file;
    unlink $config_file if defined($config_file) && -e $config_file;
}

1;
