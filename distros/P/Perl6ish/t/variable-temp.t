#!/usr/bin/env perl -w
use strict;
use warnings;

use Test::More tests => 9;

use Perl6ish;

{
    my %x = (food => 'yes', mood => 'good');
    if (1 == 1) {
        temp %x;
        is_deeply \%x, {food => 'yes', mood => 'good'};

        %x = ( how => are => you => '?');
        is_deeply \%x, {how => are => you => '?'};
    }
    is_deeply \%x, {food => 'yes', mood => 'good'};
}

{
    my @x = (1, 3, 5);
    if (1 == 1) {
        temp @x;
        is_deeply \@x, [1, 3, 5];

        @x = (2,4,6);
        is_deeply \@x, [2, 4, 6];
    }
    is_deeply \@x, [1, 3, 5];
}

{
    my $x = 5;
    if (1 == 1) {
        temp $x;
        # my $_x = $x; my $x = $_x;
        # diag $x;
        is $x, 5;
        $x++;
        # diag $x;
        is $x, 6;
    }
    # diag $x;
    is $x, 5;

}

