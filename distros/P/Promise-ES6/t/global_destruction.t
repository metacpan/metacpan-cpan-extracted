#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Promise::ES6;

#my $out = `$^X -MPromise::ES6 -e'close STDERR; open STDERR, ">>STDOUT"; my \$prm = Promise::ES6->new();'`;
my $out = `$^X -MPromise::ES6 -e'\$Promise::ES6::DETECT_MEMORY_LEAKS = 1; my \$prm = Promise::ES6->new( sub { die "abc"; } );'`;
warn "Nonzero exit: $?" if $?;

diag explain [$out];

ok 1;

done_testing();

1;
