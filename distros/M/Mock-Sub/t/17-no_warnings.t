#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use Mock::Sub no_warnings => 1;

{
    my $warn;
    $SIG{__WARN__} = sub { $warn = shift; };

    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');

    is $warn, undef, "no warning on non-existent sub if no_warnings is passed in";
}

done_testing();

