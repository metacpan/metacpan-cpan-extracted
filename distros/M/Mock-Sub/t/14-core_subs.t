#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;

use lib 't/data';

my ($mock, $caller);

BEGIN {
    use_ok('Mock::Sub');

    $mock = Mock::Sub->new;

    my $warning;
    $SIG{__WARN__} = sub { $warning = shift; };

    $caller = $mock->mock('caller');

    like ($warning, qr/WARNING!/, "mocking a core global sub warns");
};

is ($caller->mocked_state, 1, "caller() has a mock object");

# below is because CALLER::CORE doesn't show up in 5.14 and below
#FIXME

ok ($caller->name eq "CORE::GLOBAL::caller" || $caller->name eq "main::caller" , "caller() sub name is correct");

caller();

is ($caller->called, 1, "calling caller() updates the object");

$caller->return_value(55);

is (caller(), 55, "caller() can have a return value");

$caller->side_effect( sub { return 7; } );

is (caller(), 7, "...and a side effect");

is ($caller->called_count, 3, "call count is correct");

done_testing();
