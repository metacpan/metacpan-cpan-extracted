#! /usr/bin/env perl

use 5.024;
use warnings;

my %group_of = (
     cats => 'clowder',
     bats => 'colony',
    gnats => 'cloud',
     rats => 'swarm',
);

use Perl6::Controls;

try {
    CATCH { warn 'No more animals :-(' }

    loop {
        my @animals;

        repeat while (!@animals) {
            print 'Enter animals: ';
            @animals = grep {exists $group_of{$_} }
                        split /\s+/,
                        scalar readline // die;
        }

        for (%group_of{@animals}) -> $animal, $group {
            FIRST { say "\n(" }
                    say "    '$animal' => '$group',";
            LAST { say ")\n" }
        }
    }
}
