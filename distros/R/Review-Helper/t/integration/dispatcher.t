# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use Capture::Tiny qw/capture/;
use Cwd qw/getcwd/;
use File::Spec;
use File::Temp qw/tempdir/;
use TestShell qw/posix_sh/;

my $script = File::Spec->rel2abs('scripts/review-helper');
my $sh     = posix_sh() or skip_all "no /bin/sh";

# A fake implementation: prints its name and arguments, one per line. $mode
# 0644 writes one that is not executable.
sub fake($dir, $impl, $mode = 0755) {
    my $file = "$dir/review-helper-$impl";
    open(my $fh, '>', $file) or die "Could not write $file: $!";
    print $fh <<"SH";
#!$sh
if [ "\${1:-}" = version ]; then echo "standard 1"; echo "implementation fake-$impl 9"; exit 0; fi
echo $impl
for arg in "\$@"; do echo "\$arg"; done
exit 3
SH
    close($fh);
    chmod($mode, $file) or die "Could not chmod $file: $!";
    return $file;
}

# Run the dispatcher with only @dirs on PATH; return (stdout, exit, stderr).
sub run_with($impl, $dirs, @args) {
    local $ENV{PATH} = join ':' => @$dirs;
    delete local $ENV{REVIEW_HELPER_IMPL};
    $ENV{REVIEW_HELPER_IMPL} = $impl if defined $impl;
    my ($out, $err, $status) = capture { system($sh, $script, @args) };
    return ($out, $status >> 8, $err);
}

my $empty = tempdir(CLEANUP => 1);
my $both  = tempdir(CLEANUP => 1);
my $late  = tempdir(CLEANUP => 1);
my $go    = fake($late, 'go');
my $node  = fake($both, 'node');
my $perl  = fake($both, 'perl');
my $other = fake($late, 'perl');

is([run_with(undef, [$both], 'build', '--title', 'Two words')], ["node\nbuild\n--title\nTwo words\n",                                               3, ''], 'the first found runs; arguments and the exit status pass through unchanged');
is([run_with(undef, [$late, $both], 'list')],                   ["go\nlist\n",                                                                      3, ''], 'the order of PATH decides');
is([run_with(undef, [$both, $late], 'list')],                   ["node\nlist\n",                                                                    3, ''], 'and only the order of PATH');
is([run_with('perl', [$both], 'list')],                         ["perl\nlist\n",                                                                    3, ''], 'REVIEW_HELPER_IMPL picks the implementation');
is([run_with('perl', [$late, $both], '--which')],               ["  go $go\n* perl $other\n  node $node\nstandard 1\nimplementation fake-perl 9\n", 0, ''], 'the first of its name on PATH');

is(
    [run_with(undef, [$both, $late], '--which')],
    ["* node $node\n  perl $perl\n  go $go\nstandard 1\nimplementation fake-node 9\n", 0, ''],
    '--which lists each implementation once, in PATH order, marks the chosen one, then prints its versions',
);
is(
    [run_with('go', [$both, $late], '--which')],
    ["  node $node\n  perl $perl\n* go $go\nstandard 1\nimplementation fake-go 9\n", 0, ''],
    '--which follows REVIEW_HELPER_IMPL',
);

subtest 'what is not an implementation is passed over' => sub {
    my $stray = tempdir(CLEANUP => 1);
    fake($stray, 'perl', 0644);
    fake($stray, $_) for 'perl.bak', 'x.sh', 'a b';
    { open(my $fh, '>', "$stray/review-helper-") or die "Could not write: $!"; close($fh); chmod(0755, "$stray/review-helper-") }
    mkdir("$stray/review-helper-dir") or die "Could not mkdir: $!";

    is([run_with(undef, [$stray, $both], 'list')], ["node\nlist\n", 3, ''], 'non-executable files, invalid names and directories are skipped');
    is(
        [run_with('perl', [$stray, $both], '--which')],
        ["  node $node\n* perl $perl\nstandard 1\nimplementation fake-perl 9\n", 0, ''],
        'and are not listed',
    );
};

subtest 'odd PATH entries' => sub {
    my $locked = tempdir(CLEANUP => 1);
    fake($locked, 'locked');
    chmod(0000, $locked) or die "Could not chmod: $!";
    my $missing = "$empty/no-such-dir";

    is([run_with(undef, ['', $missing, $locked, $late], 'list')], [$< == 0 ? "locked\nlist\n" : "go\nlist\n", 3, ''], 'empty, missing and unreadable directories are skipped');
    chmod(0700, $locked);

    # '.' is the directory the dispatcher runs in.
    my $orig = getcwd();
    chdir($late) or die "chdir $late: $!";
    my @got = run_with(undef, ['.', $both], '--which');
    chdir($orig) or die "chdir $orig: $!";
    is(\@got, ["* go ./review-helper-go\n  perl ./review-helper-perl\n  node $node\nstandard 1\nimplementation fake-go 9\n", 0, ''], "'.' is searched like any directory");
};

my ($out, $exit, $err) = run_with(undef, [$empty], 'list');
is([$out, $exit], ['', 127], 'none found: exits 127');
like($err, qr/^review-helper: no implementation found: no executable review-helper-<impl> is on PATH$/, 'and says so');

($out, $exit, $err) = run_with('python', [$both], 'list');
is([$out, $exit], ['', 127], 'the named implementation missing: exits 127');
like($err, qr/^review-helper: REVIEW_HELPER_IMPL is 'python', but review-helper-python is not on PATH$/, 'and says which');

($out, $exit, $err) = run_with('../perl', [$both], 'list');
is([$out, $exit], ['', 2], 'a name with a slash is refused');
like($err, qr/^review-helper: REVIEW_HELPER_IMPL must be an implementation name such as perl, not '\.\.\/perl'$/, 'and says why');

done_testing;
