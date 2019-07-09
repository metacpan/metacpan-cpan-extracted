#!perl -w

use strict;
use warnings;

use Test::Compile::Internal;
use Test::More ;

plan skip_all => "Distribution hasn't been built yet" unless -d "blib/lib";

my $test = Test::Compile::Internal->new();

# lib.pl has a dodgy begin block which messes with @INC.
# - that should force it to *only* look in blib/lib for
#   modules.. but it should still compile. See rt72557
#   for more details.
my $compiles = $test->pl_file_compiles('t/scripts/lib.pl');
ok($compiles, "lib.pl compiles");

done_testing();
