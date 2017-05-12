#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use Scope::Upper qw<unwind>;

my @res;

@res = (7, eval {
 unwind;
 8;
});
is $@, '', 'unwind() does not croak';
is_deeply \@res, [ 7 ], 'unwind()';

@res = (7, eval {
 unwind -1;
 8;
});
like $@, qr/^Can't\s+return\s+outside\s+a\s+subroutine/, 'unwind(-1) croaks';
is_deeply \@res, [ 7 ], 'unwind(-1)';

@res = (7, eval {
 unwind 0;
 8;
});
like $@, qr/^Can't\s+return\s+outside\s+a\s+subroutine/, 'unwind(0) croaks';
is_deeply \@res, [ 7 ], 'unwind(0)';
