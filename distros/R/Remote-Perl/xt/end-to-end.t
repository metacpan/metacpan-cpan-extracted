use v5.36;
use Test::More;
use File::Temp qw(tempfile);
use IPC::Open3 qw(open3);
use IO::Select;
use Symbol qw(gensym);

use lib 'lib';

# -- Target interpreter --------------------------------------------------------

my $target = $ENV{REMOTE_PERL_TEST_TARGET_INTERP}
          // scalar glob('~/perl5/perlbrew/perls/stable/bin/perl');

plan skip_all => "target interpreter not found ($target)"
    unless defined $target && -x $target;

# -- Helpers -------------------------------------------------------------------

sub script($source) {
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.pl');
    print $fh $source;
    close $fh;
    return $path;
}

# Spawn bin/remperl with @args passed directly to it (must include --pipe-cmd).
# Returns (stdout, stderr, exit_code).
sub run_remperl($stdin_data, @args) {
    my ($in_fh, $out_fh, $err_fh);
    $err_fh = gensym();
    my $pid = open3($in_fh, $out_fh, $err_fh,
        $^X, '-It/lib', 'bin/remperl', @args);
    binmode($in_fh); binmode($out_fh); binmode($err_fh);

    if (defined $stdin_data) {
        print $in_fh $stdin_data;
    }
    close $in_fh;

    my ($stdout, $stderr) = ('', '');
    my $sel = IO::Select->new($out_fh, $err_fh);
    while ($sel->count) {
        for my $fh ($sel->can_read(15)) {
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

# -- Tests: without module serving ---------------------------------------------

# stdout
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, script('print "hello\n";'));
    is($rc,  0,         'stdout: exit 0');
    is($out, "hello\n", 'stdout: correct');
    is($err, '',        'stdout: no stderr');
}

# stderr
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, script('print STDERR "err\n";'));
    is($rc,  0,        'stderr: exit 0');
    is($out, '',       'stderr: no stdout');
    is($err, "err\n",  'stderr: correct');
}

# exit code
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, script('exit 42;'));
    is($rc, 42, 'exit code: passed through');
}

# stdin forwarding
{
    my ($out, $err, $rc) = run_remperl("hello\n",
        '--pipe-cmd', $target, script('my $l = <STDIN>; print "got: $l";'));
    is($rc,  0,              'stdin: exit 0');
    is($out, "got: hello\n", 'stdin: echoed correctly');
}

# @ARGV passthrough
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target,
        script('print join(", ", @ARGV), "\n";'),
        'foo', 'bar', 'hello world');
    is($rc,  0,                        'argv: exit 0');
    is($out, "foo, bar, hello world\n", 'argv: passed through');
}

# die message
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, script('die "boom\n";'));
    is($rc, 255, 'die: exit 255');
    like($err, qr/boom/, 'die: message in stderr');
}

# -e flag
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target,
        '-e', 'print "result: " . (6 * 7) . "\n";');
    is($rc,  0,              '-e: exit 0');
    is($out, "result: 42\n", '-e: expression evaluated correctly');
}

# -- Tests: module serving -----------------------------------------------------

# serve off vs serve on: identical invocation except for --serve-modules.
# The remote has no direct access to t/lib; the module can only be loaded
# when the local side serves it.
my $mod_script = script('use Remote::Perl::Test::Greeter;'
                      . 'print Remote::Perl::Test::Greeter::greet("World"), "\n";');

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, $mod_script);
    isnt($rc, 0,                 'serve off: non-zero exit');
    like($err, qr/Can't locate/, 'serve off: cannot load module');
}

{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, '--serve-modules', $mod_script);
    is($rc,  0,                'serve on: exit 0');
    is($out, "Hello, World!\n", 'serve on: module loaded and used');
    is($err, '',               'serve on: no stderr');
}

# The remote must run under $target, not under the local $^X.
SKIP: {
    skip 'target interpreter is the same as local', 3 if $target eq $^X;

    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, '--serve-modules',
        script('use Remote::Perl::Test::Greeter;'
             . 'print Remote::Perl::Test::Greeter::interpreter(), "\n";'));
    chomp(my $interp = $out);
    is($rc,     0,       'interpreter: exit 0');
    is($interp, $target, 'interpreter: matches $target');
    isnt($interp, $^X,   'interpreter: differs from local');
}

# -- Tests: --tmpfile / __DATA__ -----------------------------------------------

my $data_script = script(<<'PERL');
my $data = do { local $/; readline *main::DATA };
print "data:$data";
__DATA__
hello from data
PERL

# Without --tmpfile: code runs but __DATA__ is unreadable; warning on stderr.
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, $data_script);
    is($rc,  0,           '__DATA__ no-tmpfile: exit 0');
    isnt($out, "data:hello from data\n", '__DATA__ no-tmpfile: data not readable');
    like($err, qr/__DATA__/, '__DATA__ no-tmpfile: warning on stderr');
}

# With --tmpfile: __DATA__ is readable.
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, '--tmpfile', $data_script);
    is($rc,  0,                       '--tmpfile auto: exit 0');
    is($out, "data:hello from data\n", '--tmpfile auto: __DATA__ readable');
    is($err, '',                       '--tmpfile auto: no stderr');
}

# With --tmpfile-mode=perl explicitly.
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, '--tmpfile-mode=perl', $data_script);
    is($rc,  0,                       '--tmpfile-mode=perl: exit 0');
    is($out, "data:hello from data\n", '--tmpfile-mode=perl: __DATA__ readable');
}

# With --tmpfile-mode=named explicitly.
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, '--tmpfile-mode=named', $data_script);
    is($rc,  0,                       '--tmpfile-mode=named: exit 0');
    is($out, "data:hello from data\n", '--tmpfile-mode=named: __DATA__ readable');
}

# --no-data-warn suppresses the local remperl warning (remote script may still
# produce its own warnings because DATA is unreadable without --tmpfile).
{
    my ($out, $err, $rc) = run_remperl(undef,
        '--pipe-cmd', $target, '--no-data-warn', $data_script);
    is($rc, 0, '--no-data-warn: exit 0');
    my @remperl_warns = grep { /remperl:.*DATA/ } split /\n/, $err;
    is(scalar @remperl_warns, 0, '--no-data-warn: local remperl warning suppressed');
}

done_testing;
