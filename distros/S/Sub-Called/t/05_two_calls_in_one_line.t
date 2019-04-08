#!/usr/bin/env perl

use strict;
use warnings;
use Sub::Called;
use Test::More;

sub dummy {
    TODO: {
        local $TODO = 'Check if something changed in more recent Perl versions';
        ok( Sub::Called::with_ampersand() );
    }
}

sub foo {
    ok( ! Sub::Called::with_ampersand() );
}

my %hash = (
    dummy => &dummy,
    foo   => foo(),
);

&dummy; foo();

done_testing();
