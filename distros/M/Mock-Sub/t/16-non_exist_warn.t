#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Mock::Sub');
};

{
    my $warn;
    $SIG{__WARN__} = sub { $warn = shift; };

    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');

    like
        $warn,
        qr/we've mocked a non-existent/,
        "w/o no_warnings, we warn on non-exist sub";
}

done_testing();

