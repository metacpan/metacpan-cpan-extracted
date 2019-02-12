package PromiseTest;

use strict;
use warnings;

use parent qw(Test::Class);

use Time::HiRes;

sub await {
    my ($self, $promise) = @_;

    my %result;

    $promise->then(
        sub { $result{'resolved'} = $_[0] },
        sub { $result{'rejected'} = $_[0] },
    );

    Time::HiRes::sleep(0.01) while !keys %result;

    return $result{'resolved'} if exists $result{'resolved'};

    die $result{'rejected'};
}

1;
