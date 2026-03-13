# Tests for CLI basics: -e, --stdin-file, --stdin-str, script args, --help.
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

# Convenience wrapper: --pipe-cmd perl <script>, optional stdin.
sub run_cli($script_path, $stdin_data = undef) {
    return run_remperl($stdin_data, '--pipe-cmd', $^X, $script_path);
}

# -- Tests ---------------------------------------------------------------------

# Basic stdout
{
    my ($out, $err, $rc) = run_cli(script('print "hello from cli\n";'));
    is($rc,  0,                  'stdout: exit 0');
    is($out, "hello from cli\n", 'stdout: correct');
    is($err, '',                 'stdout: no stderr');
}

# Stderr
{
    my ($out, $err, $rc) = run_cli(script('print STDERR "oops\n";'));
    is($rc,  0,       'stderr: exit 0');
    is($out, '',      'stderr: no stdout');
    is($err, "oops\n", 'stderr: correct');
}

# Die gives exit 255
{
    my ($out, $err, $rc) = run_cli(script('die "boom\n";'));
    is($rc, 255, 'die: exit 255');
}

# Both stdout and stderr
{
    my ($out, $err, $rc) = run_cli(
        script('print "out\n"; print STDERR "err\n";'));
    is($rc,  0,      'both: exit 0');
    is($out, "out\n", 'both: stdout correct');
    is($err, "err\n", 'both: stderr correct');
}

# Stdin forwarding
{
    my ($out, $err, $rc) = run_cli(
        script('my $l = <STDIN>; print "got: $l";'),
        "hello\n");
    is($rc,  0,             'stdin: exit 0');
    is($out, "got: hello\n", 'stdin: echoed correctly');
}

# Exit code passthrough
{
    my ($out, $err, $rc) = run_cli(script('exit 42;'));
    is($rc, 42, 'exit(42): exit code passed through');
}

# Multi-line output (basic large-ish output)
{
    my $n = 1000;
    my ($out, $err, $rc) = run_cli(
        script("print \"line \$_\\n\" for 1..$n;"));
    is($rc, 0, 'multiline: exit 0');
    is(scalar(() = $out =~ /\n/g), $n, "multiline: $n lines");
}

# -e CODE
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X, '-e', 'print "result: " . (6 * 7) . "\n";');
    is($rc,  0,              '-e: exit 0');
    is($out, "result: 42\n", '-e: expression evaluated correctly');
    is($err, '',             '-e: no stderr');
}

# --stdin FILE
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    print $fh "from file\n";
    close $fh;

    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X, '--stdin-file', $path,
        script('my $l = <STDIN>; print "got: $l";'));
    is($rc,  0,                  '--stdin: exit 0');
    is($out, "got: from file\n", '--stdin: content forwarded');
}

# --help exits 0 and prints something
{
    my ($out, $err, $rc) = run_remperl(undef, '--help');
    is($rc, 0, '--help: exit 0');
    ok(length($out) > 0, '--help: printed usage');
}

# Script arguments via @ARGV
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        script('print join(", ", @ARGV), "\n";'),
        'foo', 'bar', 'hello world');
    is($rc,  0,                           'argv: exit 0');
    is($out, "foo, bar, hello world\n",   'argv: args passed through');
}

# -e with arguments
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        '-e', 'print scalar(@ARGV), "\n";',
        'a', 'b', 'c');
    is($rc,  0,      'argv -e: exit 0');
    is($out, "3\n",  'argv -e: correct count');
}

# --stdin-str passes a verbatim string as remote STDIN
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $^X,
        '--stdin-str', "strpong\n",
        script('my $l = <STDIN>; print "got: $l";'));
    is($rc,  0,                   '--stdin-str: exit 0');
    is($out, "got: strpong\n",    '--stdin-str: content forwarded');
}

done_testing;
