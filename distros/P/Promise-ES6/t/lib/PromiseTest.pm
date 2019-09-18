package PromiseTest;

use strict;
use warnings;
use autodie;

use Test::More;

use Time::HiRes;

use constant _INTERVAL => 0.01;

sub await {
    my ($promise, $checks_ar) = @_;

    my %result;

    my $await_p = $promise->then(
        sub { $result{'resolved'} = $_[0] },
        sub { $result{'rejected'} = $_[0] },
    );

    # diag 'Starting await loop';

    while (!keys %result) {
        Time::HiRes::sleep( _INTERVAL() );

        $_->() for @$checks_ar;
    }

    # diag 'Ended await loop';

    return $result{'resolved'} if exists $result{'resolved'};

    die $result{'rejected'};
}

1;
