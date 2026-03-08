use v5.36;
use Test::More;
use File::Temp qw(tempfile);

use lib 'lib';
use Remote::Perl;

sub make_r() { Remote::Perl->new(cmd => [$^X]) }

# -- run_code: stdout ----------------------------------------------------------

{
    my $r   = make_r();
    my $out = '';
    my $rc  = $r->run_code('print "hello\n";',
        on_stdout => sub { $out .= $_[0] },
    );
    is($rc,  0,          'stdout: exit 0');
    is($out, "hello\n",  'stdout: correct content');
    $r->disconnect;
}

# -- run_code: stderr ----------------------------------------------------------

{
    my $r   = make_r();
    my $err = '';
    my $rc  = $r->run_code('print STDERR "warn\n";',
        on_stderr => sub { $err .= $_[0] },
    );
    is($rc,  0,        'stderr: exit 0');
    is($err, "warn\n", 'stderr: correct content');
    $r->disconnect;
}

# -- run_code: die gives exit 255 ----------------------------------------------

{
    my $r = make_r();
    my ($rc, $msg) = $r->run_code('die "boom\n";');
    is($rc,  255,    'die: exit 255');
    like($msg, qr/boom/, 'die: message returned');
    $r->disconnect;
}

# -- run_code: stdin forwarding ------------------------------------------------

{
    my $r   = make_r();
    my $out = '';

    # Use a real pipe so IO::Select can watch for data.
    pipe(my $r_fh, my $w_fh);
    binmode($r_fh); binmode($w_fh);
    print $w_fh "ping\n";
    close $w_fh;   # EOF after one line

    my $rc = $r->run_code('my $l = <STDIN>; print "got: $l";',
        on_stdout => sub { $out .= $_[0] },
        stdin     => $r_fh,
    );
    is($rc,  0,             'stdin: exit 0');
    is($out, "got: ping\n", 'stdin: echoed correctly');
    $r->disconnect;
}

# -- run_code: no stdin provided -- script sees immediate EOF ------------------

{
    my $r  = make_r();
    my $out = '';
    my $rc = $r->run_code('my $l = <STDIN>; print defined($l) ? "got" : "eof";',
        on_stdout => sub { $out .= $_[0] },
    );
    is($rc,  0,     'no-stdin: exit 0');
    is($out, 'eof', 'no-stdin: script sees EOF');
    $r->disconnect;
}

# -- run_code: plain string as stdin -------------------------------------------

{
    my $r   = make_r();
    my $out = '';
    my $rc  = $r->run_code('my $l = <STDIN>; print "got: $l";',
        on_stdout => sub { $out .= $_[0] },
        stdin     => "pong\n",
    );
    is($rc,  0,              'stdin-str: exit 0');
    is($out, "got: pong\n",  'stdin-str: echoed correctly');
    $r->disconnect;
}

# -- run_code: multiple calls on the same connection ---------------------------

{
    my $r = make_r();
    my @out;

    my $rc1 = $r->run_code('print "one\n";',  on_stdout => sub { $out[0] .= $_[0] });
    my $rc2 = $r->run_code('print "two\n";',  on_stdout => sub { $out[1] .= $_[0] });
    my $rc3 = $r->run_code('print "three\n";', on_stdout => sub { $out[2] .= $_[0] });

    is($rc1, 0,        'multi: first exit 0');
    is($rc2, 0,        'multi: second exit 0');
    is($rc3, 0,        'multi: third exit 0');
    is($out[0], "one\n",   'multi: first output');
    is($out[1], "two\n",   'multi: second output');
    is($out[2], "three\n", 'multi: third output');

    $r->disconnect;
}

# -- run_file ------------------------------------------------------------------

{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.pl');
    print $fh 'print "from file\n";';
    close $fh;

    my $r   = make_r();
    my $out = '';
    my $rc  = $r->run_file($path, on_stdout => sub { $out .= $_[0] });

    is($rc,  0,              'run_file: exit 0');
    is($out, "from file\n",  'run_file: correct output');
    $r->disconnect;
}

done_testing;
