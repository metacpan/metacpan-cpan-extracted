# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use Capture::Tiny qw/capture/;
use Cwd qw/getcwd/;
use File::Basename qw/dirname/;
use File::Spec;
use File::Temp qw/tempdir/;
use Review::Helper;
use TestRepo qw/make_repo/;
use TestShell qw/posix_sh/;

my $script = File::Spec->rel2abs('scripts/review-helper-perl');
my $orig   = getcwd();
my $dir    = make_repo();

local $ENV{PERL5LIB} = join ':' => map { File::Spec->rel2abs($_) } grep { !ref } @INC;

# Run the installed command line from inside the repository; return (stdout, exit, stderr).
sub run_script(@args) {
    chdir($dir) or die "chdir $dir: $!";
    my ($out, $err, $status) = capture { system($^X, $script, @args) };
    chdir($orig) or die "chdir $orig: $!";
    return ($out, $status >> 8, $err);
}

my ($out, $exit) = run_script(qw/note --flag yellow --kind note --path a.txt --sentence/, 'Worth knowing.');
is($exit, 0, 'note exits 0');
like($out, qr/^[0-9a-f-]{36}\n\z/, 'note prints its id');
ok(-s "$dir/.git/review-helper/journal.jsonl", 'journal written in the worktree git directory');

($out, $exit) = run_script(qw/list/);
is([$out, $exit], ['', 0], 'list with no registry');

(undef, $exit, my $err) = run_script(qw/build --base HEAD/);
is($exit, 1, 'a failing subcommand exits non-zero');
like($err, qr/^review-helper build: /, 'and says why on standard error');

subtest 'the dispatcher runs this implementation' => sub {
    my $sh  = posix_sh() or skip_all "no /bin/sh";
    my $bin = tempdir(CLEANUP => 1);
    symlink($script, "$bin/review-helper-perl") or die "Could not link the script: $!";
    local $ENV{PATH} = join ':' => $bin, dirname($^X), File::Spec->path;
    delete local $ENV{REVIEW_HELPER_IMPL};
    my ($out, $err, $status) = capture { system($sh, File::Spec->rel2abs('scripts/review-helper'), '--which') };
    # Other implementations on the real PATH may be listed after this one.
    my $versions = "standard " . Review::Helper->STANDARD_VERSION . "\nimplementation Review-Helper $Review::Helper::VERSION\n";
    is([$status >> 8, $err], [0, ''], '--which succeeds');
    like($out, qr/\A\* perl \Q$bin\E\/review-helper-perl\n(?:  [^\n]*\n)*\Q$versions\E\z/, '--which marks it as the one it runs, then prints its versions');
};

done_testing;
