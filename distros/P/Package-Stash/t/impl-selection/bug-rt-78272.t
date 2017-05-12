#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

# https://rt.cpan.org/Public/Bug/Display.html?id=78272
my $e = $ENV{PACKAGE_STASH_IMPLEMENTATION} = "PP; exit 1";

like(
    exception { require Package::Stash },
    qr/$e is not a valid implementation for Package::Stash/,
    'Arbitrary code in $ENV throws exception'
);

like(
    exception {
        delete $INC{'Package/Stash.pm'};
        require Package::Stash;
    },
    qr/$e is not a valid implementation for Package::Stash/,
    'Sanity check: forcing package reload throws the exception again'
);

is(
    exception {
        $ENV{PACKAGE_STASH_IMPLEMENTATION} = "PP";
        delete $INC{'Package/Stash.pm'};
        require Package::Stash;
        new_ok(
            'Package::Stash' => ['Foo'],
            'Loaded and able to create instances'
        );
    },
    undef,
    'Valid $ENV value loads correctly'
);

done_testing;
