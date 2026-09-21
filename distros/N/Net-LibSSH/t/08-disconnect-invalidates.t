use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestSSHD;
use Net::LibSSH;
use POSIX ();

# ssh_disconnect() walks session->channels and frees every one of them inside
# libssh. disconnect() used to hand that straight through, so after it every
# live Net::LibSSH::Channel held a dangling ssh_channel and every
# Net::LibSSH::SFTP an sftp_session whose channel was gone.
#
# nlss_channel_check_open() could not catch it: self->channel is non-NULL, it
# just points at freed memory. The three measured crashes were
#
#   $ssh->disconnect; $ch->exec(...)      -> SIGSEGV
#   $ssh->disconnect; undef $ch           -> SIGSEGV  (svt_free -> send_eof)
#   $ssh->disconnect; $sftp->stat(...)    -> SIGSEGV
#
# The second is the worse one: it crashes over the GC path without the caller
# ever touching the channel again, so a program that disconnects and then
# simply ends segfaults while cleaning up.
#
# The session now carries a generation counter that disconnect() bumps and
# that every channel and sftp session copies at construction. A mismatch means
# libssh has already freed the C object underneath: methods croak naming the
# session, and svt_free skips the C teardown while still releasing the session
# reference and the struct.
#
# Every scenario runs in a forked child, so a regression is a failing test
# instead of `prove` going down with a SIGSEGV.

my $srv = TestSSHD->start;
plan skip_all => 'sshd or ssh-keygen not available' unless $srv;

sub connect_session {
    my $ssh = Net::LibSSH->new;
    $ssh->option(host       => $srv->host);
    $ssh->option(port       => $srv->port);
    $ssh->option(user       => scalar getpwuid($<));
    $ssh->option(knownhosts => $srv->known_hosts);
    $ssh->connect
        or die 'connect: ' . ($ssh->error // '') . "\n";
    $ssh->auth_publickey($srv->client_key)
        or die 'auth: ' . ($ssh->error // '') . "\n";
    return $ssh;
}

# Run $code in a forked child and check the one line it writes back against
# $expect (a string compared for equality, or a Regexp matched against it).
#
# With global_destruct => 1 the child leaves through a normal exit() so Perl's
# global destruction runs -- that is the "program calls disconnect() and then
# ends" case. Everywhere else the child uses POSIX::_exit to skip it, because
# $srv was inherited across fork() and shares the parent's sshd pid.
sub run_in_child {
    my ($name, $code, $expect, %opt) = @_;
    pipe(my $rd, my $wr) or die "pipe: $!";
    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        close $rd;
        my $ok = eval { print {$wr} $code->() . "\n"; 1 };
        print {$wr} 'ERROR|' . _oneline($@) . "\n" unless $ok;
        close $wr;
        if ($opt{global_destruct}) {
            # Let global destruction run, but keep this child from taking the
            # parent's sshd down with it and from emitting a second TAP plan.
            $srv->{pid} = undef;
            Test::Builder->new->no_ending(1);
            exit($ok ? 0 : 1);
        }
        POSIX::_exit($ok ? 0 : 1);
    }

    close $wr;
    my $line = <$rd>;
    close $rd;
    waitpid($pid, 0);
    my $status = $?;
    my $signal = $status & 127;

    if ($signal) {
        my $signame = $signal == 11 ? 'SIGSEGV'
                    : $signal == 6  ? 'SIGABRT'
                    :                 "signal $signal";
        fail($name);
        diag("child was killed by $signame -- disconnect() left a dangling "
            . "libssh object behind and it was used or freed afterwards.");
        return;
    }

    my $got = defined $line ? do { my $l = $line; chomp $l; $l }
                            : '(undef -- child produced no output on the pipe)';

    if (ref $expect eq 'Regexp') {
        like $got, $expect, $name;
    }
    else {
        is $got, $expect, $name;
    }

    # A clean exit code matters for the global-destruction case: the crash
    # there happens after the pipe has already carried a good-looking answer.
    if ($opt{global_destruct}) {
        is $status, 0, "$name -- child exited cleanly through global destruction";
    }
}

sub _oneline {
    my ($msg) = @_;
    $msg = defined $msg ? "$msg" : '';
    $msg =~ s/\s+/ /g;
    $msg =~ s/\s+\z//;
    return $msg;
}

# --- 1. using a channel after disconnect() croaks instead of crashing -------

# The message has to be its own; "channel is closed" is what close() says, and
# a caller that cannot tell the two apart cannot tell a channel it closed
# itself from one libssh pulled out from under it.
for my $case (
    [ exec        => sub { $_[0]->exec('echo x') } ],
    [ read        => sub { $_[0]->read           } ],
    [ write       => sub { $_[0]->write('x')     } ],
    [ send_eof    => sub { $_[0]->send_eof       } ],
    [ eof         => sub { $_[0]->eof            } ],
    [ exit_status => sub { $_[0]->exit_status    } ],
) {
    my ($method, $call) = @$case;
    run_in_child(
        "$method() after disconnect() croaks naming the session",
        sub {
            my $ssh = connect_session();
            my $ch  = $ssh->channel;
            die "channel() returned undef\n" unless defined $ch;
            $ssh->disconnect;
            my $rv = eval { $call->($ch); 1 };
            die "no croak: returned normally\n" if $rv;
            return _oneline($@);
        },
        qr/\QNet::LibSSH::Channel::$method\E: session was disconnected/,
    );
}

# --- 2. merely dropping a channel after disconnect() (the GC path) ----------

run_in_child(
    'dropping a channel after disconnect() does not crash in svt_free',
    sub {
        my $ssh = connect_session();
        my $ch  = $ssh->channel;
        die "channel() returned undef\n" unless defined $ch;
        $ssh->disconnect;
        undef $ch;          # svt_free runs right here
        return 'survived';
    },
    'survived',
);

run_in_child(
    'close() after disconnect() is a harmless no-op',
    sub {
        my $ssh = connect_session();
        my $ch  = $ssh->channel;
        die "channel() returned undef\n" unless defined $ch;
        $ssh->disconnect;
        my $ok = eval { $ch->close; $ch->close; 1 };
        die 'close() croaked: ' . _oneline($@) . "\n" unless $ok;
        undef $ch;
        return 'survived';
    },
    'survived',
);

run_in_child(
    'a session that disconnects and then ends survives global destruction',
    sub {
        # Package globals, so these are still alive when global destruction
        # starts rather than being freed at scope exit.
        our ($GD_SSH, $GD_CH);
        $GD_SSH = connect_session();
        $GD_CH  = $GD_SSH->channel;
        die "channel() returned undef\n" unless defined $GD_CH;
        $GD_SSH->disconnect;
        return 'survived';
    },
    'survived',
    global_destruct => 1,
);

run_in_child(
    'disconnect() twice is harmless with a live channel around',
    sub {
        my $ssh = connect_session();
        my $ch  = $ssh->channel;
        die "channel() returned undef\n" unless defined $ch;
        $ssh->disconnect;
        $ssh->disconnect;
        my $rv = eval { $ch->exec('echo x'); 1 };
        die "no croak: returned normally\n" if $rv;
        undef $ch;
        return _oneline($@);
    },
    qr/\QNet::LibSSH::Channel::exec\E: session was disconnected/,
);

# --- 3. the SFTP half -------------------------------------------------------

SKIP: {
    skip 'harness sshd has no sftp subsystem', 3 unless $srv->has_sftp;

    my $key = $srv->client_key;

    run_in_child(
        'stat() after disconnect() croaks naming the session',
        sub {
            my $ssh  = connect_session();
            my $sftp = $ssh->sftp;
            die "sftp() returned undef\n" unless defined $sftp;
            $ssh->disconnect;
            my $rv = eval { $sftp->stat($key); 1 };
            die "no croak: returned normally\n" if $rv;
            return _oneline($@);
        },
        qr/\QNet::LibSSH::SFTP::stat\E: session was disconnected/,
    );

    run_in_child(
        'dropping an sftp session after disconnect() does not crash in svt_free',
        sub {
            my $ssh  = connect_session();
            my $sftp = $ssh->sftp;
            die "sftp() returned undef\n" unless defined $sftp;
            $ssh->disconnect;
            undef $sftp;    # svt_free runs right here
            return 'survived';
        },
        'survived',
    );

    # An sftp session opened on a session that is still connected keeps
    # working -- the guard must not fire on a generation that matches.
    my $size = -s $key;
    run_in_child(
        'sftp session on a still-connected session is unaffected',
        sub {
            my $ssh  = connect_session();
            my $sftp = $ssh->sftp;
            die "sftp() returned undef\n" unless defined $sftp;
            my $st = $sftp->stat($key);
            die "stat() returned undef\n" unless defined $st;
            return 'size=' . $st->{size};
        },
        "size=$size",
    );
}

# --- 4. the control: no disconnect(), everything still works ----------------

# A guard that fires on every channel would make all of the above pass while
# breaking the module, so this is the half of the test that says the counter
# only invalidates what disconnect() really invalidated.
run_in_child(
    'a channel on a session that was not disconnected still works',
    sub {
        my $ssh = connect_session();
        my $ch  = $ssh->channel;
        die "channel() returned undef\n" unless defined $ch;
        $ch->exec('echo still_fine');
        my $out = $ch->read;
        chomp $out;
        my $status = $ch->exit_status;
        $ch->close;
        return "$out|$status";
    },
    'still_fine|0',
);

# A channel closed the ordinary way before the disconnect takes the other
# branch of the guard -- channel already NULL *and* the generation stale --
# and still has to report the state the caller put it in.
run_in_child(
    'a channel closed before disconnect() still reports "channel is closed"',
    sub {
        my $ssh = connect_session();
        my $ch  = $ssh->channel;
        die "channel() returned undef\n" unless defined $ch;
        $ch->exec('echo x');
        $ch->read;
        $ch->close;
        $ssh->disconnect;
        my $rv = eval { $ch->exec('echo x'); 1 };
        die "no croak: returned normally\n" if $rv;
        my $err = _oneline($@);
        undef $ch;
        return $err;
    },
    qr/\QNet::LibSSH::Channel::exec\E: channel is closed/,
);

# Opening on a disconnected session must stay a graceful undef rather than a
# croak or a crash -- that is the same contract sftp() already has on a host
# without the subsystem. (Reconnecting the same session is not tested: libssh
# 0.10.6 cannot do it at all, ssh_connect() after ssh_disconnect() times out
# whether or not a channel was ever opened.)
run_in_child(
    'channel() and sftp() on a disconnected session return undef',
    sub {
        my $ssh = connect_session();
        $ssh->disconnect;
        my $ch   = eval { $ssh->channel };
        die 'channel() croaked: ' . _oneline($@) . "\n" if $@;
        my $sftp = eval { $ssh->sftp };
        die 'sftp() croaked: ' . _oneline($@) . "\n" if $@;
        return (defined $ch ? 'ch=obj' : 'ch=undef') . '|'
             . (defined $sftp ? 'sftp=obj' : 'sftp=undef');
    },
    'ch=undef|sftp=undef',
);

done_testing;
