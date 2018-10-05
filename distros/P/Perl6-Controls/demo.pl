#! /usr/bin/env perl

use 5.024;
use warnings;

say foo($_) for 0..2;

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
            LEAVE { say "----" }
            FIRST { say "\n(" }
                    say "    '$animal' => '$group',";
            LAST { say ")\n" }
        }
    }
}

sub foo {
    my ($x) = @_;
    LEAVE { say 'leaving foo' }
    if ($x > 1) {
        return 'a';
    }
    else {
        return 'b';
    }
}
