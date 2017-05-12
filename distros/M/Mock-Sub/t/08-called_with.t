#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 22;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');
    One::foo(1, 2);

    my @args = $foo->called_with;

    is (@args, 2, "called_with() returns the proper number of args");
    is ($args[0], 1, "passing (1, 2), first arg is correct");
    is ($args[1], 2, "passing (1, 2), second arg is correct")
}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');
    One::foo(arg1 => 1, arg2 => 2);

    my %args = $foo->called_with;

    is (keys %args, 2, "hash arg returns the proper number of keys");
    is ($args{arg1}, 1, "passing arg1=>1, arg2=>2, first arg is correct");
    is ($args{arg2}, 2, "passing arg1=>1, arg2=>2, second arg is correct")
}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');
    One::foo('hello', {a => 1}, [qw(a b c)]);

    my ($scalar, $href, $aref) = $foo->called_with;

    is ($scalar, 'hello', "scalar, href, aref, scalar is correct");
    is (ref $href, 'HASH', "scalar, href, aref, href is a hash");
    is (ref $aref, 'ARRAY', "scalar, href, aref, aref is an array");

    is ($href->{a}, 1, "scalar, href, aref, href has correct data");

    is (@$aref, 3, "scalar, href, aref, aref has proper elem count");
    is ($aref->[0], 'a', "scalar, href, aref, href has correct data");
    is ($aref->[1], 'b', "scalar, href, aref, href has correct data");
    is ($aref->[2], 'c', "scalar, href, aref, href has correct data");
}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');
    One::foo('hello', {a => 1}, [qw(a b c)]);

    my @args = $foo->called_with;

    is (@args, 3, "compiling args into array has proper count");
    is (ref \$args[0], 'SCALAR', "first arg is correct");
    is (ref $args[1], 'HASH', "second arg is correct");
    is (ref $args[2], 'ARRAY', "third arg is correct");
}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');

    eval { my @args = $foo->called_with; };

    like (
        $@,
        qr/can't call called_with/,
        "called_with() dies if its called before the mocked sub has been"
    );
}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');
    One::foo();

    my @args = $foo->called_with;

    is (@args, 0, "called_with() returns an empty list if no params were used");
}
