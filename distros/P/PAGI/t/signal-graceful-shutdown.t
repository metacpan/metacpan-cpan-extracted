#!/usr/bin/env perl

# =============================================================================
# Test: Signal Handling - Graceful Shutdown
#
# Tests SIGTERM, SIGINT, and process group SIGINT (Ctrl-C simulation).
# Verifies that all workers run lifespan.shutdown on graceful termination.
#
# Runs only with RELEASE_TESTING=1 due to timing sensitivity and process
# management complexity.
# =============================================================================

use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Future::AsyncAwait;
use File::Temp qw(tempdir);
use POSIX qw(WNOHANG setpgid);
use Time::HiRes qw(time sleep);

use PAGI::Server;

plan skip_all => "Signal tests require RELEASE_TESTING=1"
    unless $ENV{RELEASE_TESTING};
plan skip_all => "Server integration tests not supported on Windows"
    if $^O eq 'MSWin32';

# =============================================================================
# Test Utilities
# =============================================================================

sub make_test_app {
    my ($tmpdir) = @_;
    return async sub {
        my ($scope, $receive, $send) = @_;

        if ($scope->{type} eq 'lifespan') {
            while (1) {
                my $event = await $receive->();
                if ($event->{type} eq 'lifespan.startup') {
                    # Write ready marker with PID
                    if (open my $fh, '>', "$tmpdir/ready_$$") {
                        print $fh $$;
                        close $fh;
                    }
                    await $send->({ type => 'lifespan.startup.complete' });
                }
                elsif ($event->{type} eq 'lifespan.shutdown') {
                    # Write shutdown marker with PID
                    if (open my $fh, '>', "$tmpdir/shutdown_$$") {
                        print $fh $$;
                        close $fh;
                    }
                    await $send->({ type => 'lifespan.shutdown.complete' });
                    return;
                }
            }
        }
        elsif ($scope->{type} eq 'http') {
            while (1) {
                my $event = await $receive->();
                last if $event->{type} ne 'http.request';
                last unless $event->{more};
            }
            await $send->({
                type    => 'http.response.start',
                status  => 200,
                headers => [['content-type', 'text/plain']],
            });
            await $send->({
                type => 'http.response.body',
                body => "OK from worker $$",
            });
        }
    };
}

sub wait_for_files {
    my ($pattern, $count, $timeout) = @_;
    $timeout //= 10;
    my $deadline = time() + $timeout;
    while (time() < $deadline) {
        my @files = glob($pattern);
        return @files if @files >= $count;
        sleep 0.1;
    }
    return glob($pattern);
}

sub get_pids_from_files {
    my (@files) = @_;
    my @pids;
    for my $file (@files) {
        if ($file =~ /_(\d+)$/) {
            push @pids, $1;
        }
    }
    return @pids;
}

sub cleanup_markers {
    my ($tmpdir) = @_;
    unlink glob("$tmpdir/ready_*");
    unlink glob("$tmpdir/shutdown_*");
}

sub wait_for_process_exit {
    my ($pid, $timeout) = @_;
    $timeout //= 10;
    my $deadline = time() + $timeout;
    while (time() < $deadline) {
        my $result = waitpid($pid, WNOHANG);
        return 1 if $result > 0;
        sleep 0.1;
    }
    return 0;
}

# =============================================================================
# Test: SIGTERM to parent - all workers run lifespan.shutdown
# =============================================================================

subtest 'SIGTERM to parent - all workers run lifespan.shutdown' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 15000 + int(rand(1000));
    my $worker_count = 3;

    cleanup_markers($tmpdir);

    my $server_pid = fork();
    die "Fork failed: $!" unless defined $server_pid;

    if ($server_pid == 0) {
        my $loop = IO::Async::Loop->new;
        my $server = PAGI::Server->new(
            app     => make_test_app($tmpdir),
            host    => '127.0.0.1',
            port    => $port,
            workers => $worker_count,
            quiet   => 1,
        );
        $loop->add($server);
        $server->listen->get;
        $loop->run;
        exit(0);
    }

    # Wait for all workers to be ready
    my @ready_files = wait_for_files("$tmpdir/ready_*", $worker_count, 10);
    is(scalar(@ready_files), $worker_count, "All $worker_count workers started");

    # Send SIGTERM to parent
    kill 'TERM', $server_pid;

    # Wait for shutdown files
    my @shutdown_files = wait_for_files("$tmpdir/shutdown_*", $worker_count, 10);
    is(scalar(@shutdown_files), $worker_count,
        "All $worker_count workers ran lifespan.shutdown");

    # Verify parent exits cleanly
    ok(wait_for_process_exit($server_pid, 10), 'Parent process exited');

    # Force cleanup if needed
    kill 'KILL', $server_pid if kill(0, $server_pid);
    waitpid($server_pid, 0);
};

# =============================================================================
# Test: SIGINT to parent - all workers run lifespan.shutdown
# =============================================================================

subtest 'SIGINT to parent - all workers run lifespan.shutdown' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 15100 + int(rand(1000));
    my $worker_count = 3;

    cleanup_markers($tmpdir);

    my $server_pid = fork();
    die "Fork failed: $!" unless defined $server_pid;

    if ($server_pid == 0) {
        my $loop = IO::Async::Loop->new;
        my $server = PAGI::Server->new(
            app     => make_test_app($tmpdir),
            host    => '127.0.0.1',
            port    => $port,
            workers => $worker_count,
            quiet   => 1,
        );
        $loop->add($server);
        $server->listen->get;
        $loop->run;
        exit(0);
    }

    # Wait for all workers to be ready
    my @ready_files = wait_for_files("$tmpdir/ready_*", $worker_count, 10);
    is(scalar(@ready_files), $worker_count, "All $worker_count workers started");

    # Send SIGINT to parent (simulates kill -INT from another terminal)
    kill 'INT', $server_pid;

    # Wait for shutdown files
    my @shutdown_files = wait_for_files("$tmpdir/shutdown_*", $worker_count, 10);
    is(scalar(@shutdown_files), $worker_count,
        "All $worker_count workers ran lifespan.shutdown");

    # Verify parent exits cleanly
    ok(wait_for_process_exit($server_pid, 10), 'Parent process exited');

    # Force cleanup if needed
    kill 'KILL', $server_pid if kill(0, $server_pid);
    waitpid($server_pid, 0);
};

# =============================================================================
# Test: SIGINT to process group - simulates Ctrl-C
# =============================================================================

subtest 'SIGINT to process group - simulates Ctrl-C' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 15200 + int(rand(1000));
    my $worker_count = 2;

    cleanup_markers($tmpdir);

    my $server_pid = fork();
    die "Fork failed: $!" unless defined $server_pid;

    if ($server_pid == 0) {
        # Become process group leader so we can test process group signals
        setpgid(0, 0);

        my $loop = IO::Async::Loop->new;
        my $server = PAGI::Server->new(
            app     => make_test_app($tmpdir),
            host    => '127.0.0.1',
            port    => $port,
            workers => $worker_count,
            quiet   => 1,
        );
        $loop->add($server);
        $server->listen->get;
        $loop->run;
        exit(0);
    }

    # Wait for all workers to be ready
    my @ready_files = wait_for_files("$tmpdir/ready_*", $worker_count, 10);
    is(scalar(@ready_files), $worker_count, "All $worker_count workers started");

    # Get the process group ID (same as server_pid since it called setpgid)
    my $pgid = getpgrp($server_pid);

    # Send SIGINT to entire process group (simulates Ctrl-C)
    # Negative PID means send to process group
    kill 'INT', -$pgid;

    # Wait for shutdown files - this is the key test!
    # Workers should IGNORE the SIGINT (inherited from parent)
    # Parent should catch SIGINT and send SIGTERM to workers
    my @shutdown_files = wait_for_files("$tmpdir/shutdown_*", $worker_count, 10);
    is(scalar(@shutdown_files), $worker_count,
        "All $worker_count workers ran lifespan.shutdown (Ctrl-C simulation)");

    # Verify parent exits cleanly
    ok(wait_for_process_exit($server_pid, 10), 'Parent process exited');

    # Force cleanup if needed
    kill 'KILL', -$pgid if kill(0, $server_pid);
    waitpid($server_pid, 0);
};

# =============================================================================
# Test: Double signal - SIGTERM then SIGTERM (idempotent)
# =============================================================================

subtest 'Double SIGTERM - idempotent shutdown' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 15300 + int(rand(1000));
    my $worker_count = 2;

    cleanup_markers($tmpdir);

    my $server_pid = fork();
    die "Fork failed: $!" unless defined $server_pid;

    if ($server_pid == 0) {
        my $loop = IO::Async::Loop->new;
        my $server = PAGI::Server->new(
            app     => make_test_app($tmpdir),
            host    => '127.0.0.1',
            port    => $port,
            workers => $worker_count,
            quiet   => 1,
        );
        $loop->add($server);
        $server->listen->get;
        $loop->run;
        exit(0);
    }

    # Wait for all workers to be ready
    my @ready_files = wait_for_files("$tmpdir/ready_*", $worker_count, 10);
    is(scalar(@ready_files), $worker_count, "All $worker_count workers started");

    # Send SIGTERM twice (some orchestrators do this)
    kill 'TERM', $server_pid;
    sleep 0.5;
    kill 'TERM', $server_pid;  # Second signal should be handled gracefully

    # Wait for shutdown files
    my @shutdown_files = wait_for_files("$tmpdir/shutdown_*", $worker_count, 10);
    is(scalar(@shutdown_files), $worker_count,
        "All $worker_count workers ran lifespan.shutdown (double signal OK)");

    # Verify parent exits cleanly (no crash from second signal)
    ok(wait_for_process_exit($server_pid, 10), 'Parent process exited cleanly');

    # Force cleanup if needed
    kill 'KILL', $server_pid if kill(0, $server_pid);
    waitpid($server_pid, 0);
};

# =============================================================================
# Test: Signal during startup - clean abort
# =============================================================================

subtest 'SIGTERM during startup - clean abort' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 15400 + int(rand(1000));
    my $worker_count = 2;

    cleanup_markers($tmpdir);

    my $server_pid = fork();
    die "Fork failed: $!" unless defined $server_pid;

    if ($server_pid == 0) {
        my $loop = IO::Async::Loop->new;
        my $server = PAGI::Server->new(
            app     => make_test_app($tmpdir),
            host    => '127.0.0.1',
            port    => $port,
            workers => $worker_count,
            quiet   => 1,
        );
        $loop->add($server);
        $server->listen->get;
        $loop->run;
        exit(0);
    }

    # Send SIGTERM very quickly - some workers may not be ready yet
    sleep 0.3;  # Brief pause to let fork happen
    kill 'TERM', $server_pid;

    # Should exit cleanly without hanging
    ok(wait_for_process_exit($server_pid, 10),
        'Server exited cleanly when signaled during startup');

    # Count how many workers got to run shutdown
    my @shutdown_files = glob("$tmpdir/shutdown_*");
    my @ready_files = glob("$tmpdir/ready_*");

    # Workers that were ready should have shutdown files
    # (some may not have started yet, that's OK)
    ok(scalar(@shutdown_files) <= scalar(@ready_files),
        'Only ready workers ran shutdown');

    # No zombies - verify with ps if available
    my $zombies = `ps -o pid,state | grep $server_pid | grep Z 2>/dev/null`;
    is($zombies, '', 'No zombie processes');

    # Force cleanup if needed
    kill 'KILL', $server_pid if kill(0, $server_pid);
    waitpid($server_pid, 0);
};

done_testing;
