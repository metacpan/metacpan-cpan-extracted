package PromiseTest;

use strict;
use warnings;
use autodie;

use Time::HiRes;

sub await {
    my ($promise, $checks_ar) = @_;

    my %result;

    $promise->then(
        sub { $result{'resolved'} = $_[0] },
        sub { $result{'rejected'} = $_[0] },
    );

    while (!keys %result) {
        Time::HiRes::sleep(0.01);

        $_->() for @$checks_ar;
    }

    return $result{'resolved'} if exists $result{'resolved'};

    die $result{'rejected'};
}

1;
