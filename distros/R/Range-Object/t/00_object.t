use strict;
use warnings;

use Test::More tests => 1;

BEGIN { use_ok 'Range::Object' };

my $tests = eval do { local $/; <DATA>; };
die "Data eval error: $@" if $@;

die "Nothing to test!" unless $tests;

require 't/tests.pl';

run_tests( $tests );

__DATA__
[
]
