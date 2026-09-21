use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestSSHD;
use Net::LibSSH;
use POSIX ();

# The session refcount chain is what keeps the underlying ssh_session
# alive when the Perl-level session variable goes away while an object
# opened on it -- a channel or an SFTP session -- is still in use.
# NLSS_Channel and NLSS_SFTP each take a reference on the session's
# blessed, magic-bearing SV at construction and release it in their
# svt_free.
#
# There are three ways to lose the session variable, and all three have
# to keep the session alive: it falls out of scope, it is undef-ed, or
# it is assigned something else. Up to 0.002 the reference was taken on
# ST(0) -- the reference scalar itself rather than the referent it
# points at -- so only the scope case survived. The other two dropped
# the referent's refcount to zero, ssh_free()d the session under a live
# channel, and segfaulted on the next call into libssh.
#
# Every scenario runs in a forked child, so a regression is reported as
# a failing test instead of taking `prove` down with a SIGSEGV.

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

# Open $what on a fresh session, then lose the session variable the way
# $mode says. In every mode the session variable is gone by the time the
# returned object is handed back -- 'scope' just lets the enclosing block
# end without saying anything about it.
sub open_and_drop {
    my ($what, $mode) = @_;
    return do {
        my $ssh = connect_session();
        my $obj = $what eq 'channel' ? $ssh->channel : $ssh->sftp;
        undef $ssh if $mode eq 'undef';
        $ssh = 42  if $mode eq 'reassign';
        $obj;
    };
}

# Run $code in a forked child and compare the one line it writes back
# with $expect (a string, or a coderef called with the child's pid).
sub run_in_child {
    my ($name, $code, $expect) = @_;
    pipe(my $rd, my $wr) or die "pipe: $!";
    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        close $rd;
        my $ok = eval { print {$wr} $code->() . "\n"; 1 };
        print {$wr} "ERROR|$@\n" unless $ok;
        close $wr;
        # POSIX::_exit skips Perl's global destruction. $srv (TestSSHD) was
        # inherited from the parent across fork() and shares the parent's sshd
        # pid; letting this child run $srv's DESTROY too would send a second
        # SIGTERM and waitpid() a process the parent still owns.
        POSIX::_exit($ok ? 0 : 1);
    }

    close $wr;
    my $line = <$rd>;
    close $rd;
    waitpid($pid, 0);
    my $signal = $? & 127;

    if ($signal) {
        my $signame = $signal == 11 ? 'SIGSEGV'
                    : $signal == 6  ? 'SIGABRT'
                    :                 "signal $signal";
        fail($name);
        diag("child was killed by $signame -- the session refcount chain did "
            . "not keep the underlying ssh_session alive while an object "
            . "opened on it was still in use.");
        return;
    }

    my $want = ref $expect ? $expect->($pid) : $expect;
    my $got  = defined $line ? $line : '(undef -- child produced no output on the pipe)';
    ok defined($line) && $line eq "$want\n", $name;
    diag("expected [$want], got [$got]")
        unless defined($line) && $line eq "$want\n";
}

for my $mode (qw( scope undef reassign )) {
    run_in_child(
        "channel stays usable after its session variable is dropped by $mode",
        sub {
            my $ch = open_and_drop(channel => $mode);
            die "channel() returned undef\n" unless defined $ch;
            $ch->exec('echo refcount_chain_' . $$);
            my $out = $ch->read;
            chomp $out;
            my $status = $ch->exit_status;
            $ch->close;
            return "$out|$status";
        },
        sub { "refcount_chain_$_[0]|0" },
    );
}

SKIP: {
    skip 'harness sshd has no sftp subsystem', 3 unless $srv->has_sftp;

    # The SFTP half of the chain is the same two lines of XS and crashed
    # the same way; stat()ing a file of known size proves the session is
    # still there rather than merely not crashing.
    my $key  = $srv->client_key;
    my $size = -s $key;

    for my $mode (qw( scope undef reassign )) {
        run_in_child(
            "sftp session stays usable after its session variable is dropped by $mode",
            sub {
                my $sftp = open_and_drop(sftp => $mode);
                die "sftp() returned undef\n" unless defined $sftp;
                my $st = $sftp->stat($key);
                die "stat() returned undef\n" unless defined $st;
                return 'size=' . $st->{size};
            },
            "size=$size",
        );
    }
}

done_testing;
