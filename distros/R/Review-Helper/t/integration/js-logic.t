# Test origin: AI
use v5.36;
use Test2::V0;

use File::Spec;

my $node = (grep { -x File::Spec->catfile($_, 'node') } File::Spec->path)[0];
skip_all "node is not installed" unless $node;

my @tests = glob('share/ux/t/*.test.mjs');
skip_all "no JavaScript tests found" unless @tests;

my $out = qx{node --test @tests 2>&1};
ok(!$?, "node --test passes") or diag $out;

done_testing;
