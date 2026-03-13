# Tests that flow control works correctly: credits are exhausted and then
# replenished, and all data arrives intact across multiple credit cycles.
use v5.36;
use Test::More;

use lib 'lib';
use Remote::Perl;

# Use a tiny window to force many credit cycles within a small data transfer.
my $WINDOW = 64;

sub make_r() {
    return Remote::Perl->new(cmd => [$^X], window => $WINDOW);
}

# -- stdout flow control -------------------------------------------------------
# Remote produces 4 KiB of output. With a 64-byte window the local side must
# grant credits many times.  Verify all bytes arrive and are correct.

{
    my $r   = make_r();
    my $out = '';
    my $rc  = $r->run_code(
        'print "x" x 4096;',
        on_stdout => sub { $out .= $_[0] },
    );
    is($rc,          0,     'stdout: exit 0');
    is(length($out), 4096,  'stdout: all 4096 bytes received');
    is($out,         'x' x 4096, 'stdout: content correct');
    $r->disconnect;
}

# -- stderr flow control -------------------------------------------------------

{
    my $r   = make_r();
    my $err = '';
    my $rc  = $r->run_code(
        'print STDERR "y" x 4096;',
        on_stderr => sub { $err .= $_[0] },
    );
    is($rc,          0,     'stderr: exit 0');
    is(length($err), 4096,  'stderr: all 4096 bytes received');
    is($err,         'y' x 4096, 'stderr: content correct');
    $r->disconnect;
}

# -- stdin flow control --------------------------------------------------------
# Local sends 4 KiB of stdin.  With a 64-byte window the remote must grant
# credits many times.  Verify the remote receives all bytes.

{
    my $r   = make_r();
    my $out = '';
    my $rc  = $r->run_code(
        'local $/; my $in = <STDIN>; print length($in), "\n";',
        on_stdout => sub { $out .= $_[0] },
        stdin     => 'z' x 4096,
    );
    is($rc,  0,        'stdin: exit 0');
    is($out, "4096\n", 'stdin: all 4096 bytes received by remote');
    $r->disconnect;
}

# -- simultaneous stdout + stdin -----------------------------------------------
# Remote echoes stdin back to stdout; both directions must flow concurrently.

{
    my $r   = make_r();
    my $out = '';
    my $payload = 'a' x 2048;
    my $rc  = $r->run_code(
        'local $/; print scalar <STDIN>;',
        on_stdout => sub { $out .= $_[0] },
        stdin     => $payload,
    );
    is($rc,          0,             'echo: exit 0');
    is(length($out), length($payload), 'echo: correct length');
    is($out,         $payload,      'echo: content correct');
    $r->disconnect;
}

# -- multiple runs on same connection ------------------------------------------
# Verify credits are correctly reset between successive runs.

{
    my $r = make_r();
    for my $i (1 .. 3) {
        my $out = '';
        my $rc  = $r->run_code(
            'print "w" x 1024;',
            on_stdout => sub { $out .= $_[0] },
        );
        is($rc,          0,     "multi-run $i: exit 0");
        is(length($out), 1024,  "multi-run $i: all bytes received");
    }
    $r->disconnect;
}

done_testing;
