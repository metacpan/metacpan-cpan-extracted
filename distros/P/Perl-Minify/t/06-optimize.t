#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Perl::Minify qw(minify);

# Constant folding (optimize => 1). Compare exact output so that a
# regression which silently stops folding, or folds incorrectly, fails.

my @cases = (
    # [ input,                 expected (optimize on),   description ]
    [ 'my $x = 2 + 3;',        'my$x=5;',                 'simple addition folds' ],
    [ 'my $x = 2 + 3 + 4;',    'my$x=9;',                 'chain 2+3+4 folds to 9' ],
    [ 'my $x = 6 * 7;',        'my$x=42;',                'multiplication folds' ],
    [ 'my $x = 2 - 3 * 4;',    'my$x=-10;',               '2-3*4 folds in precedence order' ],
    [ 'my $x = 1 + 2 * 3 + 4;', 'my$x=11;',               '1+2*3+4 folds to 11' ],
    [ 'my $x = 2**3 + 4;',     'my$x=2**3+4;',            '**-adjacent +/- left unfolded' ],
);

for my $c (@cases) {
    my ($in, $want, $desc) = @$c;
    is(minify($in, { optimize => 1 }), $want, "optimize: $desc");
}

# Default is off: no folding.
is(minify('my $x = 2 + 3;'), 'my$x=2+3;', 'no folding without optimize');

# Non-constant code is passed through unchanged by the optimizer.
my $r = minify('my $x = 1; my $y = 2; print $x + $y;', { optimize => 1 });
like($r, qr/print\$x\+\$y/, 'non-constant expression untouched') or diag "got: $r";

# Code after return is kept (dead-code removal is not implemented).
$r = minify('sub f { return 1; my $dead = 2; }', { optimize => 1 });
like($r, qr/my\$dead=2/, 'statements after return are preserved') or diag "got: $r";

done_testing;
