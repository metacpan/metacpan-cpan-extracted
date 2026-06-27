#!/usr/bin/env perl

# =============================================================================
# Test: Signal Handling - Worker Scaling (SIGTTIN/SIGTTOU)
#
# Tests dynamic worker pool adjustment via signals.
# SIGTTIN increases worker count, SIGTTOU decreases it.
#
# Runs only with RELEASE_TESTING=1 due to timing sensitivity.
# =============================================================================

use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Future::AsyncAwait;
use File::Temp qw(tempdir);
use POSIX qw(WNOHANG);
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

sub wait_for_file_count {
    my ($pattern, $count, $timeout) = @_;
    $timeout //= 10;
    my $deadline = time() + $timeout;
    while (time() < $deadline) {
        my @files = glob($pattern);
        return 1 if @files == $count;
        sleep 0.1;
    }
    return 0;
}

sub get_pids_from_files {
    my (@files) = @_;
    my @pids;
    for my $file (@files) {
        if ($file =~ /_(\d+)$/) {
            push @pids, $1;
        }
    }
    return sort { $a <=> $b } @pids;
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
# Test: SIGTTIN increases worker count
# =============================================================================

subtest 'SIGTTIN increases worker count' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 17000 + int(rand(1000));
    my $initial_workers = 2;

    cleanup_markers($tmpdir);

    my $server_pid = fork();
    die "Fork failed: $!" unless defined $server_pid;

    if ($server_pid == 0) {
        my $loop = IO::Async::Loop->new;
        my $server = PAGI::Server->new(
            app     => make_test_app($tmpdir),
            host    => '127.0.0.1',
            port    => $port,
            workers => $initial_workers,
            quiet   => 1,
        );
        $loop->add($server);
        $server->listen->get;
        $loop->run;
        exit(0);
    }

    # Wait for initial workers
    my @ready_files = wait_for_files("$tmpdir/ready_*", $initial_workers, 10);
    is(scalar(@ready_files), $initial_workers, "Started with $initial_workers workers");

    my @original_pids = get_pids_from_files(@ready_files);
    note("Original worker PIDs: @original_pids");

    # Send SIGTTIN to add a worker
    kill 'TTIN', $server_pid;

    # Wait for new worker
    @ready_files = wait_for_files("$tmpdir/ready_*", $initial_workers + 1, 10);
    is(scalar(@ready_files), $initial_workers + 1,
        "Now have " . ($initial_workers + 1) . " workers after TTIN");

    my @new_pids = get_pids_from_files(@ready_files);
    note("Worker PIDs after TTIN: @new_pids");

    # Verify original workers still running (no shutdown files)
    my @shutdown_files = glob("$tmpdir/shutdown_*");
    is(scalar(@shutdown_files), 0, "Original workers still running (no shutdown)");

    # Verify we have one new PID
    my %original = map { $_ => 1 } @original_pids;
    my @new_workers = grep { !$original{$_} } @new_pids;
    is(scalar(@new_workers), 1, "Exactly one new worker added");

    # Cleanup
    kill 'TERM', $server_pid;
    wait_for_process_exit($server_pid, 10);
    kill 'KILL', $server_pid if kill(0, $server_pid);
    waitpid($server_pid, 0);
};

# =============================================================================
# Test: SIGTTOU decreases worker count
# =============================================================================

subtest 'SIGTTOU decreases worker count' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 17100 + int(rand(1000));
    my $initial_workers = 3;

    cleanup_markers($tmpdir);

    my $server_pid = fork();
    die "Fork failed: $!" unless defined $server_pid;

    if ($server_pid == 0) {
        my $loop = IO::Async::Loop->new;
        my $server = PAGI::Server->new(
            app     => make_test_app($tmpdir),
            host    => '127.0.0.1',
            port    => $port,
            workers => $initial_workers,
            quiet   => 1,
        );
        $loop->add($server);
        $server->listen->get;
        $loop->run;
        exit(0);
    }

    # Wait for initial workers
    my @ready_files = wait_for_files("$tmpdir/ready_*", $initial_workers, 10);
    is(scalar(@ready_files), $initial_workers, "Started with $initial_workers workers");

    my @original_pids = get_pids_from_files(@ready_files);
    note("Original worker PIDs: @original_pids");

    # Send SIGTTOU to remove a worker
    kill 'TTOU', $server_pid;

    # Wait for one shutdown file
    my @shutdown_files = wait_for_files("$tmpdir/shutdown_*", 1, 10);
    is(scalar(@shutdown_files), 1, "One worker gracefully shutdown");

    my @shutdown_pids = get_pids_from_files(@shutdown_files);
    note("Shutdown worker PID: @shutdown_pids");

    # Verify the shutdown PID was one of the originals
    my %original = map { $_ => 1 } @original_pids;
    ok($original{$shutdown_pids[0]}, "Shutdown worker was from original pool");

    # Verify we now have initial_workers - 1 ready files
    # (remove the shutdown one from ready files)
    unlink $shutdown_files[0] =~ s/shutdown_/ready_/r;
    @ready_files = glob("$tmpdir/ready_*");
    is(scalar(@ready_files), $initial_workers - 1,
        "Now have " . ($initial_workers - 1) . " workers after TTOU");

    # Cleanup
    kill 'TERM', $server_pid;
    wait_for_process_exit($server_pid, 10);
    kill 'KILL', $server_pid if kill(0, $server_pid);
    waitpid($server_pid, 0);
};

# =============================================================================
# Test: SIGTTOU minimum 1 worker
# =============================================================================

subtest 'SIGTTOU minimum 1 worker' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 17200 + int(rand(1000));
    my $initial_workers = 1;

    cleanup_markers($tmpdir);

    my $server_pid = fork();
    die "Fork failed: $!" unless defined $server_pid;

    if ($server_pid == 0) {
        my $loop = IO::Async::Loop->new;
        my $server = PAGI::Server->new(
            app     => make_test_app($tmpdir),
            host    => '127.0.0.1',
            port    => $port,
            workers => $initial_workers,
            quiet   => 1,
        );
        $loop->add($server);
        $server->listen->get;
        $loop->run;
        exit(0);
    }

    # Wait for initial worker
    my @ready_files = wait_for_files("$tmpdir/ready_*", $initial_workers, 10);
    is(scalar(@ready_files), $initial_workers, "Started with $initial_workers worker");

    my @original_pids = get_pids_from_files(@ready_files);

    # Send SIGTTOU - should be ignored (can't go below 1)
    kill 'TTOU', $server_pid;

    # Give it time to potentially (incorrectly) kill the worker
    sleep 1;

    # Verify no shutdown occurred
    my @shutdown_files = glob("$tmpdir/shutdown_*");
    is(scalar(@shutdown_files), 0, "No worker shutdown (minimum 1 worker)");

    # Verify worker still running
    @ready_files = glob("$tmpdir/ready_*");
    is(scalar(@ready_files), 1, "Still have 1 worker");

    my @current_pids = get_pids_from_files(@ready_files);
    is(\@current_pids, \@original_pids, "Same worker still running");

    # Cleanup
    kill 'TERM', $server_pid;
    wait_for_process_exit($server_pid, 10);
    kill 'KILL', $server_pid if kill(0, $server_pid);
    waitpid($server_pid, 0);
};

# =============================================================================
# Test: Scale up then down
# =============================================================================

subtest 'Scale up then down' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 17300 + int(rand(1000));
    my $initial_workers = 2;

    cleanup_markers($tmpdir);

    my $server_pid = fork();
    die "Fork failed: $!" unless defined $server_pid;

    if ($server_pid == 0) {
        my $loop = IO::Async::Loop->new;
        my $server = PAGI::Server->new(
            app     => make_test_app($tmpdir),
            host    => '127.0.0.1',
            port    => $port,
            workers => $initial_workers,
            quiet   => 1,
        );
        $loop->add($server);
        $server->listen->get;
        $loop->run;
        exit(0);
    }

    # Wait for initial workers
    my @ready_files = wait_for_files("$tmpdir/ready_*", $initial_workers, 10);
    is(scalar(@ready_files), $initial_workers, "Started with $initial_workers workers");
    note("Initial: " . scalar(@ready_files) . " workers");

    # Scale up to 3
    kill 'TTIN', $server_pid;
    @ready_files = wait_for_files("$tmpdir/ready_*", 3, 10);
    is(scalar(@ready_files), 3, "Scaled up to 3 workers");
    note("After TTIN: " . scalar(@ready_files) . " workers");

    # Scale up to 4
    kill 'TTIN', $server_pid;
    @ready_files = wait_for_files("$tmpdir/ready_*", 4, 10);
    is(scalar(@ready_files), 4, "Scaled up to 4 workers");
    note("After TTIN: " . scalar(@ready_files) . " workers");

    # Scale down to 3
    kill 'TTOU', $server_pid;
    my @shutdown_files = wait_for_files("$tmpdir/shutdown_*", 1, 10);
    is(scalar(@shutdown_files), 1, "One worker shutdown");

    # Remove the shutdown worker's ready file for accurate count
    for my $sf (@shutdown_files) {
        my $rf = $sf =~ s/shutdown_/ready_/r;
        unlink $rf;
    }
    @ready_files = glob("$tmpdir/ready_*");
    is(scalar(@ready_files), 3, "Scaled down to 3 workers");
    note("After TTOU: " . scalar(@ready_files) . " workers");

    # Scale down to 2
    kill 'TTOU', $server_pid;
    @shutdown_files = wait_for_files("$tmpdir/shutdown_*", 2, 10);
    is(scalar(@shutdown_files), 2, "Two total workers shutdown");

    for my $sf (@shutdown_files) {
        my $rf = $sf =~ s/shutdown_/ready_/r;
        unlink $rf;
    }
    @ready_files = glob("$tmpdir/ready_*");
    is(scalar(@ready_files), 2, "Scaled down to 2 workers");
    note("After TTOU: " . scalar(@ready_files) . " workers");

    # Parent still running
    ok(kill(0, $server_pid), "Parent still running after scaling");

    # Cleanup
    kill 'TERM', $server_pid;
    wait_for_process_exit($server_pid, 10);
    kill 'KILL', $server_pid if kill(0, $server_pid);
    waitpid($server_pid, 0);
};

done_testing;
