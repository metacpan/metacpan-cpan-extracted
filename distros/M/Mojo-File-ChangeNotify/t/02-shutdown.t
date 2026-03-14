#!perl
use 5.020;
use experimental "signatures";
use Test2::V0 '-no_srand';

use Mojo::File::ChangeNotify;
use File::Temp 'tempdir';
use File::Spec;
use Mojo::Promise;
use Scalar::Util 'weaken';

if( $^O =~ /mswin/i ) {
    SKIP: {
        skip_all("The tests test a subprocess but Win32 uses threads")
    }
}

# Helper to check if a PID is running (not a zombie)
sub pid_is_running($pid) {
    my $timeout = time +2;

RETRY:
    # kill 0 returns true for zombies too, so we need to check the process state
    my $result = kill 0 => $pid;
    return 0 unless $result;

    # Check if the process is a zombie via /proc
    if (open my $fh, '<', "/proc/$pid/stat") {
        my $stat = <$fh>;
        # The process state is the 3rd field; Z indicates zombie
        my @fields = split ' ', $stat;
        return 0 if @fields >= 3 && $fields[2] eq 'Z';
    }

    if( time < $timeout ) {
        sleep 1;
        goto RETRY;
    }

    return 1;
}

sub wait_poll( $timeout, $poll ) {
    my $res;
    my $status = Mojo::Promise->new();
    $status->then(
      sub( @success ) {
        $res = $success[0];
      },
      sub ($err) {
        $res = $err;
      }
    )
    #->finally(sub { say "*** done" })
    ;

    my $poller = Mojo::IOLoop->recurring( 0.1 => sub {
        $poll->($status)
    });
    $status->wait;
    Mojo::IOLoop->remove( $poller );
    return $res;
}

# Helper to wait for subprocess to spawn and get PID
sub get_watcher_pid($watcher) {
    # Run event loop to let subprocess spawn
    my $w = $watcher;
    weaken $w;
    my $pid;
    my $timeout = time+4;
    my $timer; $timer = Mojo::IOLoop->recurring(0.1 => sub($loop) {
        if(    ! $w
            or $pid = $w->watcher_pid
            or time > $timeout ) {
            $loop->remove($timer);
            $loop->stop;
        }
    });
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

    # Use the stored PID from watcher_pid attribute
    die "Subprocess never spawned (pid is undefined)" unless $pid;
    return $pid;
}

my $tempdir = tempdir(CLEANUP => 1);

#=====================================================================
# Part 2: Normal Shutdown Tests
#=====================================================================

subtest "Test 1: Scope-based cleanup" => sub {
    my $pid;
    {
        my $w = Mojo::File::ChangeNotify->instantiate_watcher(
            directories => [$tempdir],
        );
        $pid = get_watcher_pid($w);
        ok pid_is_running($pid), "Child process $pid is running while watcher in scope";
    }
    # Block ends, DESTROY should kill the child
    my $status = wait_poll( 2, sub($r) {
        if( !pid_is_running($pid)) {
            $r->resolve('gone');
        };
    });

    ok $status !~ /\btimeout\b/, "Child process $pid was killed when watcher went out of scope"
        or diag $status;
};

subtest "Test 2: Explicit undef" => sub {
    my $w = Mojo::File::ChangeNotify->instantiate_watcher(
        directories => [$tempdir],
    );
    my $pid = get_watcher_pid($w);
    ok pid_is_running($pid), "Child process $pid is running";

    undef $w;
    my $status = wait_poll( 2, sub($r) {
        if( !pid_is_running($pid)) {
            $r->resolve('gone');
        };
    });
    ok $status !~ /\btimeout\b/, "Child process $pid was killed when watcher undefined";
};

subtest "Test 3: Multiple sequential watchers" => sub {
    my @pids;
    for my $i (1..3) {
        my $w = Mojo::File::ChangeNotify->instantiate_watcher(
            directories => [$tempdir],
        );
        my $pid = get_watcher_pid($w);
        push @pids, $pid;

        ok pid_is_running($pid), "Watcher $i child process $pid is running";

        # Previous pids should be dead
        for my $prev_pid (@pids[0..$#pids-1]) {
            ok !pid_is_running($prev_pid), "Previous child $prev_pid is no longer running";
        }
    }
    # Last watcher goes out of scope here
    my $status = wait_poll( 2, sub($r) {
        if( !pid_is_running($pids[-1])) {
            $r->resolve('gone');
        };
    });
    ok $status !~ /\btimeout\b/, "Final child process was killed";
};

#=====================================================================
# Part 3: Abrupt Termination Tests
#=====================================================================

subtest "Test 4: Parent die() with END block cleanup" => sub {
    # Create a temporary perl script that will die
    my $script = File::Spec->catfile($tempdir, 'die_test.pl');
    open my $fh, '>', $script or die "Cannot create $script: $!";
    print $fh <<'END_SCRIPT';
    use 5.020;
    use experimental "signatures";
    use lib 'lib';
    use Mojo::File::ChangeNotify;
    use File::Temp 'tempdir';

    my $test_temp = $ARGV[0];

    my $tempdir = tempdir(CLEANUP => 1);
    my $w = Mojo::File::ChangeNotify->instantiate_watcher(
        directories => [$tempdir],
    );

    # Wait for child to start
    # Wait for child to start
    my $timeout = time+2;
    Mojo::IOLoop->recurring( 0.2, sub {
        my $loop = $_[0];
        if(    $w->watcher_pid
            or time >= $timeout) {
            $loop->stop;
        }
    });
    Mojo::IOLoop->start if not Mojo::IOLoop->is_running;
    if( time >= $timeout ) {
        die "Couldn't launch watcher for \$tempdir?!";
    }

    my $pid = $w->watcher_pid;

    # Write PID to file so parent can check
    open my $out, '>', "$test_temp/test4.pid"
        or die "Couldn't create '$test_temp/test4.pid': $!";
    print $out $pid, "\n";
    close $out;

    die "Abrupt termination test\n";
END_SCRIPT
    close $fh;

    # Run the script - it will die but END block should clean up
    note "Launching '$script' in '$tempdir'";
    system($^X, $script, $tempdir);
    my $exit = $? >> 8;
    ok $exit != 0, "Script died as expected";

    # Read the PID and check if it's still running
    my $pid_file = File::Spec->catfile($tempdir, 'test4.pid');
    if (open my $pf, '<', $pid_file) {
        my $child_pid = <$pf>;
        chomp $child_pid;

        my $status = wait_poll( 2, sub($r) {
            if( !pid_is_running($child_pid)) {
                $r->resolve('gone');
            };
        });
        ok $status !~ /\btimeout\b/, "Child $child_pid was killed by END block after die()";
    } else {
        fail "Could not read PID file";
    }
};

subtest "Test 5: eval { die } pattern" => sub {
    my $pid;
    eval {
        my $w = Mojo::File::ChangeNotify->instantiate_watcher(
            directories => [$tempdir],
        );
        $pid = get_watcher_pid($w);
        die "Test exception\n";
    };
    like $@, qr/Test exception/, "Exception was raised";

    # DESTROY should have run during exception handling
    ok !pid_is_running($pid), "Child $pid was killed when eval died";
};

subtest "Test 6: Multiple watchers with abrupt exit" => sub {
    my $script = File::Spec->catfile($tempdir, 'multi_die_test.pl');
    open my $fh, '>', $script or die "Cannot create $script: $!";
    print $fh <<"END_SCRIPT";
use 5.020;
use experimental "signatures";
use lib 'lib';
use Mojo::File::ChangeNotify;
use File::Temp 'tempdir';
use Mojo::IOLoop;

my \$tempdir = tempdir(CLEANUP => 1);
my \@watchers;
my \@pids;

for my \$i (1..3) {
    my \$w = Mojo::File::ChangeNotify->instantiate_watcher(
        directories => [\$tempdir],
    );
    push \@watchers, \$w;

    # Wait for child to start
    my \$timeout = time+2;
    Mojo::IOLoop->recurring( 0.2, sub {
        my \$loop = \$_[0];
        if(    \$watchers[-1]->watcher_pid
            or time >= \$timeout) {
            \$loop->stop;
        }
    });
    Mojo::IOLoop->start if not Mojo::IOLoop->is_running;
    if( time >= \$timeout ) {
        die "Couldn't launch watcher for \$tempdir?!";
    }
    push \@pids, \$w->watcher_pid;
}

# Write PIDs to file
open my \$out, '>', '$tempdir/test6.pids';
print \$out join("\\n", \@pids), "\\n";
close \$out;

die "Abrupt termination with multiple watchers\\n";
END_SCRIPT
    close $fh;

    system($^X, $script);

    my $pid_file = File::Spec->catfile($tempdir, 'test6.pids');
    if (open my $pf, '<', $pid_file) {
        my @pids = map { chomp; $_ } <$pf>;
        close $pf;

        for my $pid (@pids) {
            ok !pid_is_running($pid), "Child $pid was killed by END block after die()";
        }
    } else {
        SKIP: {
            skip "Could not read PIDs file", 3;
        }
    }
};

#=====================================================================
# Part 4: Multiple Watchers Tests
#=====================================================================

subtest "Test 7: Multiple concurrent watchers" => sub {
    my @watchers;
    my @pids;

    # Create 3 watchers
    for my $i (1..3) {
        push @watchers, Mojo::File::ChangeNotify->instantiate_watcher(
            directories => [$tempdir],
        );
        push @pids, get_watcher_pid($watchers[-1]);
    }

    # All should be running
    for my $pid (@pids) {
        ok pid_is_running($pid), "Child $pid is running";
    }

    # Let all go out of scope
    @watchers = ();

    # All should be dead
    my $status = wait_poll( 2, sub($r) {
        if( ! grep { pid_is_running($_) } @pids) {
            $r->resolve('gone');
        };
    });
    ok $status !~ /\btimeout\b/, "All children were killed";
};

subtest "Test 8: Selective watcher destruction" => sub {
    my $w1 = Mojo::File::ChangeNotify->instantiate_watcher(
        directories => [$tempdir],
    );
    my $pid1 = get_watcher_pid($w1);

    my $w2 = Mojo::File::ChangeNotify->instantiate_watcher(
        directories => [$tempdir],
    );

    my $pid2 = get_watcher_pid($w2);

    my $w3 = Mojo::File::ChangeNotify->instantiate_watcher(
        directories => [$tempdir],
    );
    my $pid3 = get_watcher_pid($w3);

    # All running
    ok pid_is_running($pid1), "Watcher 1 child $pid1 is running";
    ok pid_is_running($pid2), "Watcher 2 child $pid2 is running";
    ok pid_is_running($pid3), "Watcher 3 child $pid3 is running";

    # Kill w2
    undef $w2;
    ok !pid_is_running($pid2), "Watcher 2 child $pid2 was killed";
    ok pid_is_running($pid1), "Watcher 1 child $pid1 still running";
    ok pid_is_running($pid3), "Watcher 3 child $pid3 still running";

    # Kill w1
    undef $w1;
    ok !pid_is_running($pid1), "Watcher 1 child $pid1 was killed";
    ok pid_is_running($pid3), "Watcher 3 child $pid3 still running";

    # Kill w3
    undef $w3;
    ok !pid_is_running($pid3), "Watcher 3 child $pid3 was killed";
};

subtest "Test 9: Multiple watchers with abrupt termination (END block)" => sub {
    # This is similar to Test 6 but verifies END block specifically
    my $script = File::Spec->catfile($tempdir, 'multi_end_test.pl');
    open my $fh, '>', $script or die "Cannot create $script: $!";
    print $fh <<"END_SCRIPT";
use 5.020;
use lib 'lib';
use Mojo::File::ChangeNotify;
use File::Temp 'tempdir';

my \$tempdir = tempdir(CLEANUP => 1);
my \@watchers;

for my \$i (1..3) {
    push \@watchers, Mojo::File::ChangeNotify->instantiate_watcher(
        directories => [\$tempdir],
    );
    # Wait for child to start
    my \$timeout = time+2;
    Mojo::IOLoop->recurring( 0.2, sub {
        my \$loop = \$_[0];
        if(    \$watchers[-1]->watcher_pid
            or time >= \$timeout) {
            \$loop->stop;
        }
    });
    Mojo::IOLoop->start if not Mojo::IOLoop->is_running;
    if( time >= \$timeout ) {
        die "Couldn't launch watcher for \$tempdir?!";
    }
}

my \@pids = map { \$_->watcher_pid } \@watchers;
open my \$out, '>', '$tempdir/test9.pids';
print \$out join("\\n", \@pids), "\\n";

END {
    # This is where cleanup happens
}
# Normal exit, triggering END block
END_SCRIPT
    close $fh;

    system($^X, $script);

    my $pid_file = File::Spec->catfile($tempdir, 'test9.pids');
    if (open my $pf, '<', $pid_file) {
        my @pids = map { chomp; $_ } <$pf>;
        close $pf;

        for my $pid (@pids) {
            my $status = wait_poll( 2, sub($r) {
                if( !pid_is_running($pid)) {
                    $r->resolve('gone');
                };
            });
            ok $status !~ /\btimeout\b/, "Child $pid was killed by END block after normal exit";
        }
    } else {
        fail "Could not read PIDs file";
    }
};

#=====================================================================
# Part 5: Edge Cases
#=====================================================================

subtest "Test 10: PID already dead (zombie/already exited)" => sub {
    my $w = Mojo::File::ChangeNotify->instantiate_watcher(
        directories => [$tempdir],
    );
    my $pid = get_watcher_pid($w);
    ok pid_is_running($pid), "Child $pid is running";

    # Kill the child manually
    kill KILL => $pid;
    ok !pid_is_running($pid), "Child $pid was manually killed";

    # DESTROY should handle this gracefully
    my $ok = eval { undef $w; 1 };
    ok $ok, "DESTROY handles already-dead PID gracefully";
};

subtest "Test 11: Forked parent with copied watcher" => sub {
    my $w = Mojo::File::ChangeNotify->instantiate_watcher(
        directories => [$tempdir],
    );
    my $parent_pid = get_watcher_pid($w);
    ok pid_is_running($parent_pid), "Original child $parent_pid is running";

    my $fork_pid = fork;
    if (!defined $fork_pid) {
        skip "Cannot fork on this system", 1;
    } elsif ($fork_pid == 0) {
        # Child process
        # The watcher object is copied including the watcher_pid
        # When this child exits, DESTROY will kill the shared subprocess
        # This demonstrates the orphan scenario
        exit 0;  # Normal exit
    } else {
        # Parent process
        waitpid($fork_pid, 0);

        # The original watcher child is KILLED by the child process's DESTROY
        # This is the limitation: forking after creating a watcher causes issues
        ok !pid_is_running($parent_pid),
            "Original child $parent_pid was killed by child process DESTROY (fork limitation)";
    }
};

done_testing;
