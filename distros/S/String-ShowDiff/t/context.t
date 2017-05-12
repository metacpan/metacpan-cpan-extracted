#!/usr/bin/perl

use strict;

use String::ShowDiff qw/ansi_colored_diff/;
use Term::ANSIColor qw/:constants uncolor colored/;

use constant TEST_STRINGS => (
    "Honsetie is for the most part less proftable than dishonesty.",
    "Honesty is for the most part less profitable than dishonesty. -- Plato"
);

use constant TEST_OPTIONS => map {[$_->[0], [split //, $_->[1]], [split //, $_->[2]]]}
(
    [{context => '.*', gap => ''},
     "Honsestiye is for the most part less profitable than dishonesty. -- Plato",
     "uuu-u+u-+-uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu+uuuuuuuuuuuuuuuuuuuuuu+++++++++"
    ],
    [{context => '.*', gap => 'this should not be visible'},
     "Honsestiye is for the most part less profitable than dishonesty. -- Plato",
     "uuu-u+u-+-uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu+uuuuuuuuuuuuuuuuuuuuuu+++++++++"
    ],
    [{context => '.{0,3}', gap => ' ... '},
     "Honsestiye is ... rofitab ... ty. -- Plato",
     "uuu-u+u-+-uuuuuuuuuuu+uuuuuuuuuuu+++++++++"
    ],
    [{context => '\w*', gap => ' '},
     "Honsestiye profitable  -- Plato",
     "uuu-u+u-+-uuuuu+uuuuuu+++++++++"
    ],
);

use constant COLORS => {
    'u' => 'reset',
    '+' => 'on_green',
    '-' => 'on_red',
};

use Test::More tests => 4;

foreach (TEST_OPTIONS) {
    my ($options, $s12, $mod) = @$_;
    is ansi_colored_diff(TEST_STRINGS,$options),
       join("", map {colored($s12->[$_],COLORS->{$mod->[$_]})} (0 .. @{$mod}-1)),
       "Checking options context=" . $options->{context} . " gap= " . $options->{gap};
}

print RESET;    
