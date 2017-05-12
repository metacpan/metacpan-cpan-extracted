use strict;
use warnings;

use Test::More;
END { done_testing }

use Statistics::ChiSquare;

note("data tests");
is(
    # Uses Jon Orwant's original data
    chisquare( 500, 500 ),
    "There's a >99% chance, and a <100% chance, that this data is random.",
    "There's a >99% chance, and a <100% chance, that this data is random."
);
is(
    # Uses Jon Orwant's original data
    chisquare([1,4,2,6,5,5]),
    "There's a >30% chance, and a <50% chance, that this data is random.",
    "There's a >30% chance, and a <50% chance, that this data is random."
);
is(
    # uses David Cantrell's data
    chisquare( map { 500 } 1 .. 28 ),
    "There's a >99% chance, and a <100% chance, that this data is random.",
    "There's a >99% chance, and a <100% chance, that this data is random."
);
is(
    # uses David Cantrell's data
    chisquare( 1 .. 28 ),
    "There's a <1% chance that this data is random.",
    "There's a <1% chance that this data is random."
);
is(
    # uses wikibooks data
    chisquare(
        619, 598, 611, 569, 613, 612, 600, 579, 571, 537, 658, 599, 586, 542,
        587, 620, 581, 623, 584, 587, 616, 588, 593, 563, 593, 612, 621, 589,
        608, 646, 616, 632, 618, 592, 580, 552, 612, 623, 626, 614, 623, 618,
        634, 595, 586, 601, 601, 599, 604, 626, 610, 576, 608, 613, 582, 581,
        571, 598, 635, 608, 617, 631, 630, 616, 620, 566, 591, 579, 570, 610,
        590, 603, 598, 598, 598, 556, 596, 595, 572, 596, 560, 605, 588, 633,
        589, 568, 602, 620, 595, 665, 581, 598, 593, 651, 606, 610, 596, 593,
        558, 618, 
),
    "There's a >50% chance, and a <75% chance, that this data is random.",
    "There's a >50% chance, and a <75% chance, that this data is random."
);

note("error tests");
is(
    chisquare( 1 .. 1001 ),
    "I can't handle 1001 choices without a better table.",
    "I can't handle 1001 choices without a better table."
);
is(
    chisquare(1),
    "Not enough data!",
    "Not enough data!"
);
is(
    chisquare(),
    "There's no data!",
    "There's no data!"
);
is(
    chisquare(qw(elephant grape)),
    "Malformed data!",
    "Malformed data!"
);
is(
    chisquare([1,4,2,6,5,5], 4),
    "Malformed data!",
    "Malformed data!"
);
