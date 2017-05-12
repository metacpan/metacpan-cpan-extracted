#!/usr/bin/perl

use strict;
use warnings;

use String::Defer;
use t::Utils;

BEGIN {
    if ($] >= 5.010) {
        require feature;
        feature->import(":5.10");
    }
    else {
        no warnings "once";
        *state = sub { };
        use vars '$st';
    }
}

my $object = String::Defer->new(\(my $targ = "foo"));
my $x = "X";
our $our;
my (%hash, @array);

{   package t::Tie;
    no warnings "once";
    sub TIESCALAR { bless [] }
    *TIEARRAY = \&TIESCALAR;
    *TIEHASH = \&TIESCALAR;
    sub FETCH { String::Defer->new(\$targ) }
}

for (
    ['$object',     "object"        ],
    ['$ts',         "tied scalar"   ],
    ['$ta[0]',      "tied array"    ],
    ['$th{a}',      "tied hash"     ],
) {
    my ($defer, $dtype) = @$_;

    for (
        ["$defer",                  "$dtype"                    ],
        [qq/"A$defer"/,             "interpolated $dtype"       ],
        [qq/"A $defer B"/,          "3-way interpolated $dtype" ],
        [qq/"\$x:$defer"/,          "2 interps, $dtype first"   ],
        [qq/"$defer:\$x"/,          "2 interps, $dtype last"    ],
        ["<<DEFER\nA $defer B\nDEFER\n",
                                    "$dtype in here-doc"        ],
    ) {
        my ($expr, $etype) = @$_;

        my $lx;
        state $st;

        for (
            ["$expr",               "$etype",                   ],

            ["my \$y = $expr",      "fresh lexical = $etype"    ],
            ["\$lx = $expr",        "existing lexical = $etype" ],
        ( $] >= 5.010 ? (
            ["state \$y = $expr",   "fresh state = $etype"      ],
            ["\$st = $expr",        "existing state = $etype"   ],
        ) : () ),

            ["\$::g = $expr",       "global = $etype"           ],
            ["\$our = $expr",       "our = $etype"              ],

            ["\$hash{a} = $expr",   "hash elem = $etype"        ],
            ["\$array[0] = $expr",  "array elem = $etype"       ],
        ) {
            my ($eval, $name) = @$_;

            # Don't move these up: they need to be new each time, or we
            # don't see the failures.
            tie my $ts, "t::Tie";
            tie my @ta, "t::Tie";
            tie my %th, "t::Tie";

            note "EVAL: [$eval]";
            my $val = eval $eval;

            ok defined $val,        "$name succeeds"
                or diag "\$\@: $@";

            TODO: {
                $name =~ /^existing/ and $etype =~ /interps|3-way/
                    and local $TODO = "extra stringify on lexicals";
                
                $dtype eq "tied scalar" and $etype ne $dtype
                    and $] < 5.014
                    and local $TODO = "overload fails on tied scalars";

                is_defer $val,          "$name gives a String::Defer";
            }
        }
    }
}

done_testing;
