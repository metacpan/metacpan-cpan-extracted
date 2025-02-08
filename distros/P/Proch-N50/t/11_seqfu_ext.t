#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";  # Add the lib directory to @INC

# Make sure the module loads
require_ok('Proch::Seqfu');
Proch::Seqfu->import();

# Test individual function imports
ok(defined &seqfu_version, 'seqfu_version function is exported');
ok(defined &has_seqfu, 'has_seqfu function is exported');

# Test seqfu_version
my $iVersion;
eval {
    $iVersion = seqfu_version();
};
is($@, '', "seqfu_version() executed without errors");
diag("seqfu_version returned: " . (defined $iVersion ? $iVersion : 'undef'));

# Test has_seqfu
my $has_seqfu;
eval {
    $has_seqfu = has_seqfu();
};
is($@, '', "has_seqfu() executed without errors");

SKIP: {
    skip "has_seqfu() failed to execute", 1 if $@;
    ok(
        (!defined $has_seqfu || $has_seqfu == 0 || $has_seqfu == 1),
        "has_seqfu() returned valid value (" . (defined $has_seqfu ? $has_seqfu : 'undef') . ")"
    );
}

done_testing();