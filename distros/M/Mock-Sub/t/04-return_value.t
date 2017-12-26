#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 27;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# return_value

    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo', return_value => 'True');
    Two::test;
    my $ret = Two::test;

    is ($foo->called_count, 2, "mock obj with return_value has right call count");
    is ($ret, 'True', "mock obj with return_value has right ret val");

}
{# return_value
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');

    my $ret = One::foo();
    is ($ret, undef, "no return_value set yet");

    $foo->return_value(50);
    $ret = Two::test;
    is ($ret, 50, "return_value() does the right thing when adding");

    $foo->return_value('hello');
    $ret = Two::test;
    is ($ret, 'hello', "return_value() updates the value properly");

    $foo->return_value(undef);
    $ret = Two::test;
    is (ref $ret, 'One', "return_value() undef's the value properly");
}
{# return_value

    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');
    $foo->return_value(qw(1 2 3));
    my @ret = One::foo;

    is (@ret, 3, "return_value returns list when asked");
    is ($ret[0], 1, "return_value list has correct data");
    is ($ret[2], 3, "return_value list has correct data");
}
{# return_value

    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');
    $foo->return_value('hello');
    my @ret = One::foo;
    my $ret = One::foo;

    is (@ret, 1, "return_value returns list in context with only a scalar");
    is ($ret[0], 'hello', "return_value list has correct data");
    is ($ret, 'hello', "in scalar context with a single param, we get data");

    $foo->return_value(qw(hello world));
    $ret = One::foo();

    is ($ret, 2, "in scalar context with list sent in, count is returned");

}
{# return_value in new()

    my $mock = Mock::Sub->new(return_value => 'in_new');

    my $ret;

    my $foo = $mock->mock('One::foo');
    $ret = One::foo();
    is ($ret, 'in_new', "1st object uses return_value from new()");

    my $bar = $mock->mock('One::bar');
    $ret = One::bar();
    is ($ret, 'in_new', "1st object uses return_value from new()");

    $foo->return_value(undef);
    $ret = One::foo();
    is ($ret, undef, "1st object return_value is undef after reset");

    $ret = One::bar();
    is (
        $ret,
        'in_new',
        "2nd obj return_value remains from new() after 1st was reset"
    );

    $foo->return_value('out_of_new');
    $ret = One::foo();
    is ($ret, 'out_of_new', "1st object return_value obeys return_value()");

    $ret = One::bar();
    is (
        $ret,
        'in_new',
        "2nd obj return_value remains after 1st changed again"
    );

    $bar->return_value(undef);
    $ret = One::bar();
    is ($ret, undef, "2nd object can reset return_value independently");

    $ret = One::foo();
    is ($ret, 'out_of_new', "...and 1st object is unaffected");

    my $mock2 = Mock::Sub->new(return_value => 'mock2');

    my $baz = $mock2->mock('One::baz');
    $ret = One::baz();
    is ($ret, 'mock2', "new obj with new mock sets return_value in new");

    $ret = One::foo();
    is ($ret, 'out_of_new', "...and objects created with 1st mock are ok");

    $baz->return_value('mock2_call');
    $ret = One::baz();
    is ($ret, 'mock2_call', "obj with 2nd mock return_value() works");

    $ret = One::bar();
    is ($ret, undef, "...and objects created by first mock are unaffected");

}
