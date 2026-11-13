# Test origin: AI
use v5.36;
use Test2::V0;

use File::Basename qw/dirname/;
use File::Spec;
use File::Temp qw/tempdir/;

# The command-line conformance checks are the repository's backend-neutral
# tests; a built distribution does not carry them.
my $checks = File::Spec->rel2abs(File::Spec->catdir(File::Spec->updir, 'conformance', 'cli'));
skip_all "the conformance CLI checks are not here (run from perl/ in a checkout)" unless -d $checks;

my ($node) = grep { -x } map { File::Spec->catfile($_, 'node') } File::Spec->path;
skip_all "node is not installed" unless $node;

# This checkout's command, alone on PATH under its implementation name.
my $bin = tempdir(CLEANUP => 1);
symlink(File::Spec->rel2abs('scripts/review-helper-perl'), "$bin/review-helper-perl") or die "Could not link the command: $!";

local $ENV{PATH}               = join ':' => $bin, dirname($^X), File::Spec->path;
local $ENV{PERL5LIB}           = join ':' => map { File::Spec->rel2abs($_) } grep { !ref } @INC;
local $ENV{REVIEW_HELPER_IMPL} = 'perl';
delete local $ENV{REVIEW_HELPER_REVIEWER};
delete local $ENV{REVIEW_HELPER_PORT_COMMAND};
delete local $ENV{REVIEW_HELPER_LISTEN};

my $out = qx{"$node" --test --test-reporter=tap "$checks" 2>&1};
my $ok  = !$?;
ok($ok, "the CLI conformance checks pass") or diag $out;
note join ", " => $out =~ m/^# ((?:tests|pass|fail) \d+)$/mg;

done_testing;
