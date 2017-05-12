#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# mock() instantiate

    my $mock = Mock::Sub->new;
    my $test = $mock->mock('One::foo');
    is (ref $test, 'Mock::Sub::Child', "$mock->mock() returns a child object");

    Two::test;
    is ($test->called_count, 1, "instantiating with mock() can call methods");
}
{# new() instantiate

    my $mock = Mock::Sub->new;
    is (ref $mock, 'Mock::Sub', "instantiating with new() works");

    my $test = $mock->mock('One::foo');
    Two::test;
    is ($test->called_count, 1, "instantiating within an object works");
}
{ 
    my $mock = Mock::Sub->new;
    is (ref $mock, 'Mock::Sub', "instantiating with new() works");
    
    my $test1 = $mock->mock('One::foo');
    my $test2 = $mock->mock('One::bar');
    my $test3 = $mock->mock('One::baz');

    Two::test;
    Two::test2;
    Two::test2;
    Two::test3;
    Two::test3;
    Two::test3;

    is ($test1->called_count, 1, "1st mock from object does the right thing");
    is ($test2->called_count, 2, "2nd mock from object does the right thing");
    is ($test3->called_count, 3, "3rd mock from object does the right thing");

    Two::test;
    Two::test2;
    Two::test2;
    Two::test3;
    Two::test3;
    Two::test3;

    is ($test1->called_count, 2, "2nd 1st mock from object does the right thing");
    is ($test2->called_count, 4, "2nd 2nd mock from object does the right thing");
    is ($test3->called_count, 6, "2nd 3rd mock from object does the right thing");
}
{
    my $warn;
    $SIG{__WARN__} = sub {$warn = 'warned'};
    my $mock = Mock::Sub->new;
    my $test4 = $mock->mock('X::Yes');
    is ($warn, 'warned', "mocking a non-existent sub results in a warning");
}
{
    my $mock = Mock::Sub->new;
    my $test5;
    eval { $test5 = $mock->mock('testing', return_value => 'True'); };
    is ($test5->{name}, 'main::testing', "main:: gets prepended properly");
    is ($@, '', "sub param automatically gets main:: if necessary");
    is (testing(), 'True', "sub in main:: is called properly")
}
{
    $SIG{__WARN__} = sub {};
    my $mock = Mock::Sub->new;
    my $fake = $mock->mock('X::y', return_value => 'true');
    my $ret = X::y();
    is ($ret, 'true', "successfully mocked a non-existent sub")
}
{
    eval { my $foo = Mock::Sub->mock('One::foo'); };
    like ($@, qr/no longer permitted/, "can't call mock() from the Mock::Sub class");
}
{# new() w/side_effect
    my $mock = Mock::Sub->new(side_effect => sub { return 55; });
    is (ref $mock, 'Mock::Sub', "instantiating with new() works");
    my $test = $mock->mock('One::foo');
    my $ret = Two::test;
    is ($ret, 55, "instantiating with side_effect works");
}
{# new() w/side_effect

    my $mock = Mock::Sub->new(side_effect => {a => 1});
    is (ref $mock, 'Mock::Sub', "bad side_effect in new for mock works");
    eval { my $test = $mock->mock('One::foo'); };
    like ($@, qr/side_effect parameter must be a code/, "croaks if side_effect in new is bad");
}
{# new() w/side_effect - Child.pm

    eval { my $child = Mock::Sub::Child->new(side_effect => sub { return 55; }); };
    is ($@, '', "instantiating with side_effect in Child works");
}
{# new() w/side_effect

    eval { my $child = Mock::Sub::Child->new(side_effect => {a => 1}); };
    like ($@, qr/side_effect parameter must be a code/, "croaks if side_effect in new is bad");
}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');

    delete $foo->{name};

    eval { $foo->_mock('One::foo'); };

    like ($@, qr/can't call mock\(\) on a child object/, "can't call mock() from the Mock::Sub class");
}

done_testing();

sub testing {
    return 'testing';
}
