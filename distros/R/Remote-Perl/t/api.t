# Tests for the Remote::Perl library API: run_code, run_file, I/O callbacks, exit codes.
use v5.36;
use Test::More;
use File::Temp qw(tempfile);

use lib 'lib';
use Remote::Perl;

sub make_r() { Remote::Perl->new(cmd => [$^X]) }

# -- run_code: basic I/O, die, pid, run_file -----------------------------------

{
    my $r = make_r();

    # stdout
    {
        my $out = '';
        my $rc  = $r->run_code('print "hello\n";',
            on_stdout => sub { $out .= $_[0] },
        );
        is($rc,  0,         'stdout: exit 0');
        is($out, "hello\n", 'stdout: correct content');
    }

    # stderr
    {
        my $err = '';
        my $rc  = $r->run_code('print STDERR "warn\n";',
            on_stderr => sub { $err .= $_[0] },
        );
        is($rc,  0,        'stderr: exit 0');
        is($err, "warn\n", 'stderr: correct content');
    }

    # die gives exit 255
    {
        my ($rc, $msg) = $r->run_code('die "boom\n";');
        is($rc,  255,        'die: exit 255');
        like($msg, qr/boom/, 'die: message returned');
    }

    # multiple calls on the same connection
    {
        my @out;
        my $rc1 = $r->run_code('print "one\n";',   on_stdout => sub { $out[0] .= $_[0] });
        my $rc2 = $r->run_code('print "two\n";',   on_stdout => sub { $out[1] .= $_[0] });
        my $rc3 = $r->run_code('print "three\n";', on_stdout => sub { $out[2] .= $_[0] });
        is($rc1, 0,           'multi: first exit 0');
        is($rc2, 0,           'multi: second exit 0');
        is($rc3, 0,           'multi: third exit 0');
        is($out[0], "one\n",   'multi: first output');
        is($out[1], "two\n",   'multi: second output');
        is($out[2], "three\n", 'multi: third output');
    }

    # pid
    ok($r->pid > 0, 'pid: returns a positive integer');

    # run_file
    {
        my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.pl');
        print $fh 'print "from file\n";';
        close $fh;
        my $out = '';
        my $rc  = $r->run_file($path, on_stdout => sub { $out .= $_[0] });
        is($rc,  0,             'run_file: exit 0');
        is($out, "from file\n", 'run_file: correct output');
    }

    $r->disconnect;
}

# -- run_code: stdin variants --------------------------------------------------

{
    my $r = make_r();

    # stdin forwarding via pipe
    {
        # Use a real pipe so IO::Select can watch for data.
        pipe(my $r_fh, my $w_fh);
        binmode($r_fh); binmode($w_fh);
        print $w_fh "ping\n";
        close $w_fh;   # EOF after one line
        my $out = '';
        my $rc  = $r->run_code('my $l = <STDIN>; print "got: $l";',
            on_stdout => sub { $out .= $_[0] },
            stdin     => $r_fh,
        );
        is($rc,  0,             'stdin: exit 0');
        is($out, "got: ping\n", 'stdin: echoed correctly');
    }

    # no stdin -- script sees immediate EOF
    {
        my $out = '';
        my $rc  = $r->run_code('my $l = <STDIN>; print defined($l) ? "got" : "eof";',
            on_stdout => sub { $out .= $_[0] },
        );
        is($rc,  0,     'no-stdin: exit 0');
        is($out, 'eof', 'no-stdin: script sees EOF');
    }

    # plain string as stdin
    {
        my $out = '';
        my $rc  = $r->run_code('my $l = <STDIN>; print "got: $l";',
            on_stdout => sub { $out .= $_[0] },
            stdin     => "pong\n",
        );
        is($rc,  0,             'stdin-str: exit 0');
        is($out, "got: pong\n", 'stdin-str: echoed correctly');
    }

    $r->disconnect;
}

# -- send_signal ---------------------------------------------------------------
# Script traps SIGTERM, prints "ready" to signal it is waiting, then sleeps.
# The on_stdout callback fires send_signal('TERM') once it sees the sentinel,
# which causes the executor to exit 0 via the trap handler.

{
    my $r    = make_r();
    my $out  = '';
    my $sent = 0;
    my $rc   = $r->run_code(
        '$SIG{TERM} = sub { print "got TERM\n"; exit 0 }; '
      . 'print "ready\n"; sleep 5;',
        on_stdout => sub {
            $out .= $_[0];
            if (!$sent && $out =~ /ready/) {
                $sent = 1;
                $r->send_signal('TERM');
            }
        },
    );
    is($rc,  0,                   'send_signal: exit 0');
    is($out, "ready\ngot TERM\n", 'send_signal: signal delivered to executor');
    $r->disconnect;
}

# -- connection failure: stderr captured in die message ------------------------
# Exercises Transport::stderr_ready and Transport::read_stderr via the
# _connect failure path.  The child prints the sentinel then closes stdout
# (triggering the failure) while keeping stdin open so HELLO can be written
# without EPIPE.

{
    eval {
        Remote::Perl->new(cmd => [$^X, '-e',
            '$|=1; print "REMOTEPERL1\n"; close STDOUT; '
          . 'print STDERR "connect-fail-test\n"; '
          . '1 while sysread STDIN, my $b, 4096',
        ]);
    };
    like($@, qr/connection failed.*connect-fail-test/s,
        'connection failure: stderr captured in die message');
}

done_testing;
