#!/usr/bin/env perl

# XXX Test::Exception...

use strict;
use warnings;

use Test::More tests => 18;

BEGIN { use_ok('Scope::Guard', 'guard') };

my $test_0 = 'test_0';
my $test_1 = 'test_1';
my $test_2 = 'test_2';

eval {
    $test_0 = 'modified test_0';
    guard { $test_1 = 'modified test_1' }; # void context: blow up
    $test_2 = 'modified test_2'; # not reached
};

like $@, qr{Can't create a Scope::Guard in void context};
is $test_0, 'modified test_0';
is $test_1, 'test_1';
is $test_2, 'test_2';

####################################################

my $test_3 = 'test_3';
my $test_4 = 'test_4';

sub {
    my $guard = guard { $test_3 = 'modified test_3' };
    return;
    $test_4 = 'modified test 4';
}->();

is $test_3, 'modified test_3';
is $test_4, 'test_4';

####################################################

my $test_5 = 'test_5';
my $test_6 = 'test_6';

eval {
    my $guard = guard { $test_5 = 'modified test_5' };

    my $numerator = 42;
    my $denominator = 0;
    my $exception = $numerator / $denominator;

    $test_6 = 'modified test 3'; # not reached
};

like $@, qr{^Illegal division by zero};
is $test_5, 'modified test_5';
is $test_6, 'test_6';

####################################################

my $test_7 = 'test_7';
my $test_8 = 'test_8';

{
    my $guard = guard { $test_7 = 'modified test_7' }; # not called (due to dismiss())
    $guard->dismiss(); # defaults to true
    $test_8 = 'modified test_8'; # reached!
}

is $test_7, 'test_7'; # unmodified
is $test_8, 'modified test_8'; # the guard was dismissed, so this is reached

####################################################

my $test_9 = 'test_9';
my $test_10 = 'test_10';

{
    my $guard = guard { $test_9 = 'modified test_9' }; # not called (due to dismiss())
    $guard->dismiss(1);
    $test_10 = 'modified test_10'; # reached!
}

is $test_9, 'test_9';
is $test_10, 'modified test_10';

####################################################

my $test_11 = 'test_11';
my $test_12 = 'test_12';

{
    my $guard = guard { $test_11 = 'modified test_11' };
    $guard->dismiss(); # dismiss: default argument (1)
    $guard->dismiss(0); # un-dismiss!
    $test_12 = 'modified test_12';
}

is $test_11, 'modified test_11';
is $test_12, 'modified test_12';

####################################################

my $test_13 = 'test_13';
my $test_14 = 'test_14';

{
    my $guard = guard { $test_13 = 'modified test_13' };
    $guard->dismiss(1);  # dismiss: explicit argument (1)
    $guard->dismiss(0); # un-dismiss!
    $test_14 = 'modified test_14';
}

is $test_13, 'modified test_13';
is $test_14, 'modified test_14';
