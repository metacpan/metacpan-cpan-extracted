#!/usr/bin/env perl

# =============================================================================
# Test: Signal Handling - Graceful Restart (SIGHUP)
#
# Tests SIGHUP for zero-downtime worker replacement.
# Verifies old workers shutdown gracefully and new workers start.
#
# Runs only with RELEASE_TESTING=1 due to timing sensitivity.
# =============================================================================

use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use IO::Socket::INET;
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

            # Check for slow request
            my $qs = $scope->{query_string} // '';
            my ($delay) = $qs =~ /delay=(\d+)/;
            if ($delay) {
                await IO::Async::Loop->new->delay_future(after => $delay);
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
# Test: SIGHUP replaces all workers
# =============================================================================

subtest 'SIGHUP replaces all workers' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 16000 + int(rand(1000));
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

    # Wait for initial workers to be ready
    my @ready_files = wait_for_files("$tmpdir/ready_*", $worker_count, 10);
    is(scalar(@ready_files), $worker_count, "Initial $worker_count workers started");

    my @original_pids = get_pids_from_files(@ready_files);
    note("Original worker PIDs: @original_pids");

    # Clear markers before HUP
    cleanup_markers($tmpdir);

    # Send SIGHUP to trigger graceful restart
    kill 'HUP', $server_pid;

    # Wait for old workers to shutdown
    my @shutdown_files = wait_for_files("$tmpdir/shutdown_*", $worker_count, 10);
    is(scalar(@shutdown_files), $worker_count,
        "All $worker_count original workers ran lifespan.shutdown");

    my @shutdown_pids = get_pids_from_files(@shutdown_files);
    is(\@shutdown_pids, \@original_pids,
        "Shutdown PIDs match original PIDs");

    # Wait for new workers to start
    @ready_files = wait_for_files("$tmpdir/ready_*", $worker_count, 10);
    is(scalar(@ready_files), $worker_count, "New $worker_count workers started");

    my @new_pids = get_pids_from_files(@ready_files);
    note("New worker PIDs: @new_pids");

    # Verify new PIDs are different from original
    my %original = map { $_ => 1 } @original_pids;
    my @overlap = grep { $original{$_} } @new_pids;
    is(scalar(@overlap), 0, "New workers have different PIDs than originals");

    # Verify parent is still running (same PID)
    ok(kill(0, $server_pid), "Parent process still running after HUP");

    # Cleanup
    kill 'TERM', $server_pid;
    wait_for_process_exit($server_pid, 10);
    kill 'KILL', $server_pid if kill(0, $server_pid);
    waitpid($server_pid, 0);
};

# =============================================================================
# Test: SIGHUP during active request - request completes
# =============================================================================

subtest 'SIGHUP during active request - request completes' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 16100 + int(rand(1000));
    my $worker_count = 1;  # Single worker for simpler testing

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

    # Wait for worker to be ready
    my @ready_files = wait_for_files("$tmpdir/ready_*", $worker_count, 10);
    is(scalar(@ready_files), $worker_count, "Worker started");

    # Start a slow request in a child process
    my $client_pid = fork();
    die "Fork failed: $!" unless defined $client_pid;

    if ($client_pid == 0) {
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 10,
        );
        exit(1) unless $sock;

        # Request with 2 second delay
        print $sock "GET /?delay=2 HTTP/1.1\r\n";
        print $sock "Host: 127.0.0.1:$port\r\n";
        print $sock "Connection: close\r\n";
        print $sock "\r\n";

        # Read response
        my $response = '';
        while (my $line = <$sock>) {
            $response .= $line;
        }
        close $sock;

        # Exit 0 if we got a complete response
        if ($response =~ /HTTP\/1\.[01] 200/ && $response =~ /OK from worker/) {
            exit(0);
        }
        exit(1);
    }

    # Give request time to start
    sleep 0.5;

    # Clear markers and send HUP during request
    cleanup_markers($tmpdir);
    kill 'HUP', $server_pid;

    # Wait for client to complete
    my $client_exited = wait_for_process_exit($client_pid, 10);
    my $client_status = $? >> 8;

    ok($client_exited, "Client process completed");
    is($client_status, 0, "Request completed successfully during HUP");

    # Wait for new worker to start
    my @new_ready_files = wait_for_files("$tmpdir/ready_*", $worker_count, 10);
    is(scalar(@new_ready_files), $worker_count, "New worker started after HUP");

    # Cleanup
    kill 'TERM', $server_pid;
    wait_for_process_exit($server_pid, 10);
    kill 'KILL', $server_pid if kill(0, $server_pid);
    kill 'KILL', $client_pid if kill(0, $client_pid);
    waitpid($server_pid, 0);
    waitpid($client_pid, 0);
};

# =============================================================================
# Test: Multiple SIGHUP in sequence
# =============================================================================

subtest 'Multiple SIGHUP in sequence' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $port = 16200 + int(rand(1000));
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

    # Wait for initial workers
    my @ready_files = wait_for_files("$tmpdir/ready_*", $worker_count, 10);
    is(scalar(@ready_files), $worker_count, "Initial workers started");

    my @gen1_pids = get_pids_from_files(@ready_files);
    note("Gen1 worker PIDs: @gen1_pids");

    # First HUP
    cleanup_markers($tmpdir);
    kill 'HUP', $server_pid;

    # Wait for replacement
    my @shutdown_files = wait_for_files("$tmpdir/shutdown_*", $worker_count, 10);
    is(scalar(@shutdown_files), $worker_count, "Gen1 workers shutdown");

    @ready_files = wait_for_files("$tmpdir/ready_*", $worker_count, 10);
    is(scalar(@ready_files), $worker_count, "Gen2 workers started");

    my @gen2_pids = get_pids_from_files(@ready_files);
    note("Gen2 worker PIDs: @gen2_pids");

    # Second HUP
    cleanup_markers($tmpdir);
    kill 'HUP', $server_pid;

    # Wait for second replacement
    @shutdown_files = wait_for_files("$tmpdir/shutdown_*", $worker_count, 10);
    is(scalar(@shutdown_files), $worker_count, "Gen2 workers shutdown");

    @ready_files = wait_for_files("$tmpdir/ready_*", $worker_count, 10);
    is(scalar(@ready_files), $worker_count, "Gen3 workers started");

    my @gen3_pids = get_pids_from_files(@ready_files);
    note("Gen3 worker PIDs: @gen3_pids");

    # Verify all generations have different PIDs
    my %all_pids;
    $all_pids{$_}++ for (@gen1_pids, @gen2_pids, @gen3_pids);
    my @duplicates = grep { $all_pids{$_} > 1 } keys %all_pids;
    is(scalar(@duplicates), 0, "All generations have unique PIDs");

    # Parent still running
    ok(kill(0, $server_pid), "Parent still running after multiple HUPs");

    # Cleanup
    kill 'TERM', $server_pid;
    wait_for_process_exit($server_pid, 10);
    kill 'KILL', $server_pid if kill(0, $server_pid);
    waitpid($server_pid, 0);
};

done_testing;
