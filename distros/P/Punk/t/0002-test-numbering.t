#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The numbering scheme, enforced.
#
# t/ was renumbered from a flat two-digit space that had run out: 96 files
# in 100 slots, with eight numbers held by two files each. A number that
# identifies two files is not an identifier, and the header comments that
# cite tests by number stopped resolving.
#
# The scheme that replaced it only stays true if something checks. Nothing
# else can: a duplicate number is not a syntax error, an unbanded file
# still runs, and the suite passes either way. This file is the check.
#
#   NNNN-name.t   four digits, then a lowercase hyphenated name
#
# The leading digits place the file in a band of 100 that says what it
# tests. Inside a band numbers step by one, and sub-groups start on a
# multiple of ten - so a new store goes beside the stores, and there is
# always room between one group and the next.
#
# plan_punk_test_renumber/ has the map and the reasoning.

my @BANDS = (
    [    0, 'dist meta, load, ABI and refcount guards' ],
    [  100, 'DSL, import, routing, dispatch'           ],
    [  200, 'request, response, context'               ],
    [  300, 'views and static assets'                  ],
    [  400, 'file delivery and uploads'                ],
    [  500, 'the model tier'                           ],
    [  600, 'OpenAPI, docs, markdown'                  ],
    [  700, 'security'                                 ],
    [  800, 'cache'                                    ],
    [  900, 'session and flash'                        ],
    [ 1000, 'async: futures, SSE, WebSocket, bus'      ],
    [ 1100, 'HTTP-semantics plugins'                   ],
    [ 1200, 'ops: config, proxy, rate limit, log, UA'  ],
    [ 1300, 'tooling: CLI, scaffolder, test client'    ],
);
my %BAND = map { $_->[0] => $_->[1] } @BANDS;

opendir(my $dh, 't') or plan skip_all => "no t/ to read: $!";
my @t = sort grep { /\.t\z/ } readdir $dh;
closedir $dh;

plan skip_all => 'no test files found' unless @t;

# ---- shape -------------------------------------------------------------
# Anything that does not match cannot be placed in a band, so this runs
# first and the rest only looks at what passed.

my @named;
for my $f (@t) {
    if ($f =~ /\A([0-9]{4})-[a-z0-9]+(?:-[a-z0-9]+)*\.t\z/) {
        push @named, [ $f, $1 + 0 ];
    }
    else {
        fail("t/$f is NNNN-name.t");
        diag("  four digits, hyphen, then a lowercase hyphenated name");
    }
}
ok(scalar @named == scalar @t, 'every file in t/ is numbered NNNN-name.t');

# ---- uniqueness --------------------------------------------------------
# The failure that forced the renumber. Two files on one number is the
# thing this whole scheme exists to prevent, so it is worth naming both.

my %seen;
push @{ $seen{ $_->[1] } }, $_->[0] for @named;
my @dupes = sort { $a <=> $b } grep { @{ $seen{$_} } > 1 } keys %seen;
is(scalar @dupes, 0, 'no number is used twice')
    or diag(sprintf("  %04d: %s", $_, join ', ', @{ $seen{$_} })) for @dupes;

# ---- bands -------------------------------------------------------------
# A file outside every declared band is not necessarily wrong - it may be
# a new subject that deserves one. But it should be a decision somebody
# made rather than a number somebody reached for, so adding a band here is
# the deliberate step that makes it pass.

for my $n (@named) {
    my ($file, $num) = @$n;
    my $band = int($num / 100) * 100;
    ok(exists $BAND{$band}, sprintf("t/%s is in a declared band (%04d)", $file, $band))
        or diag("  no band $band; add it to \@BANDS if this is a new subject");
}

done_testing;
