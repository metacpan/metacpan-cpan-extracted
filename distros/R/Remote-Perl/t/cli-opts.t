# Tests for bin/remperl option parsing.
use v5.36;
use Test::More;
use File::Temp qw(tempfile);
use IPC::Open3 qw(open3);
use IO::Select;
use Symbol qw(gensym);

use lib 'lib';

# -- Helpers -------------------------------------------------------------------

# Write a throwaway script and return its path.
sub script($source) {
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.pl');
    print $fh $source;
    close $fh;
    return $path;
}

# Run the CLI with arbitrary arguments, optionally writing $stdin_data to its stdin.
# Returns (stdout, stderr, exit_code).
sub run_remperl($stdin_data, @args) {
    my ($in_fh, $out_fh, $err_fh);
    $err_fh = gensym();
    my $pid = open3($in_fh, $out_fh, $err_fh,
        $^X, 'bin/remperl', @args);
    binmode($in_fh); binmode($out_fh); binmode($err_fh);

    if (defined $stdin_data) {
        print $in_fh $stdin_data;
    }
    close $in_fh;

    # Drain stdout and stderr with select to avoid deadlock.
    my ($stdout, $stderr) = ('', '');
    my $sel = IO::Select->new($out_fh, $err_fh);
    while ($sel->count) {
        for my $fh ($sel->can_read(5)) {
            my $buf;
            my $n = sysread($fh, $buf, 65536);
            if (!$n) { $sel->remove($fh); next }
            if (fileno($fh) == fileno($out_fh)) { $stdout .= $buf }
            else                                 { $stderr .= $buf }
        }
    }

    waitpid($pid, 0);
    return ($stdout, $stderr, $? >> 8);
}

# -- Tests: -w enables warnings ------------------------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        '-w', '-e', 'my $x; print $x;');
    like($err, qr/uninitialized/, '-w: warning about uninitialized value');
}

# -- Tests: -Mstrict -----------------------------------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        '-Mstrict', '-e', '$x = 1; print "bad\n";');
    isnt($rc, 0, '-Mstrict: dies on undeclared variable');
}

# -- Tests: -MScalar::Util=looks_like_number -----------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        '-MScalar::Util=looks_like_number', '-e',
        'print looks_like_number(42) ? "yes" : "no";');
    is($rc,  0,    '-MScalar::Util=looks_like_number: exit 0');
    is($out, 'yes', '-MScalar::Util=looks_like_number: function works');
}

# -- Tests: -M-warnings suppresses warnings ------------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        '-w', '-M-warnings', '-e', 'my $x; print $x; print "ok";');
    is($rc,  0,    '-M-warnings: exit 0');
    is($out, 'ok', '-M-warnings: output correct');
    is($err, '',   '-M-warnings: no warnings on stderr');
}

# -- Tests: bundled -wMFoo -e works --------------------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        '-wMScalar::Util=looks_like_number',
        '-e', 'print looks_like_number("abc") ? "yes" : "no";');
    is($rc,  0,   'bundled -wM: exit 0');
    is($out, 'no', 'bundled -wM: function works');
}

# -- Tests: options after script are NOT treated as remperl options (short) ----

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        script('print join(",", @ARGV), "\n";'),
        '-e', 'not code');
    is($rc,  0,                  'post-script short opt: exit 0');
    is($out, "-e,not code\n",    'post-script -e passed as script arg');
}

# -- Tests: options after script are NOT treated as remperl options (long) -----

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        script('print join(",", @ARGV), "\n";'),
        '--rsh', 'foo');
    is($rc,  0,                  'post-script long opt: exit 0');
    is($out, "--rsh,foo\n",      'post-script --rsh passed as script arg');
}

# -- Tests: multiple -e --------------------------------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        '-e', 'print "a";', '-e', 'print "b";');
    is($rc,  0,    'multiple -e: exit 0');
    is($out, 'ab', 'multiple -e: both evaluated');
}

# -- Tests: -m/-M with script file is an error ---------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        '-mstrict', script('print 1;'));
    isnt($rc, 0,                             '-m with script: non-zero exit');
    like($err, qr/-m\/-M requires -e/, '-m with script: correct error');
}

# -- Tests: -h prints help and exits 0 -----------------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef, '-h');
    is($rc, 0, '-h: exit 0');
    ok(length($out) > 0, '-h: printed usage');
}

# -- Tests: -V prints version and exits 0 --------------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef, '-V');
    is($rc, 0, '-V: exit 0');
    like($out, qr/remperl \d/, '-V: printed version');
}

# -- Tests: -- stops option processing -----------------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        '-e', 'print join(",", @ARGV)',
        '--', '--foo', 'bar');
    is($rc,  0,            '"--": exit 0');
    is($out, '--foo,bar',  '"--": args after -- passed as script args');
}

# -- Tests: missing argument for -e --------------------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef, '-e');
    isnt($rc, 0,                               'missing -e arg: non-zero exit');
    like($err, qr/missing argument for -e/,    'missing -e arg: correct error');
}

# -- Tests: unknown long option ------------------------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef, '--unknown-option');
    isnt($rc, 0,                               'unknown long opt: non-zero exit');
    like($err, qr/Unknown option/,             'unknown long opt: error message');
}

# -- Tests: unrecognized switch ------------------------------------------------

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X, '-z', '-e', '1');
    isnt($rc, 0, 'unknown -z: non-zero exit');
    like($err, qr/unrecognized switch: -z/, 'unknown -z: correct error');
}

done_testing;
