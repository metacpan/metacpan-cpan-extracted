use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use MooseX::Declare;

class UnderTest {
    method pass_through (:$param?) {
        $param;
    }

    method pass_through2 (:name($value)?) {
        $value;
    }

    method pass_through3 ($value?) {
        $value || 'default';
    }
}

is(UnderTest->new->pass_through(param => "send reinforcements, we're going to advance")
    => "send reinforcements, we're going to advance",
    "send three and fourpence, we're going to a dance");

is( exception {
    is(UnderTest->new->pass_through2(name => "foo")
       => "foo",
       "should be 'foo'");
}, undef, 'name => $value');

is( exception {
    is(UnderTest->new->pass_through3()
       => "default",
       "should be 'default'");
}, undef, 'optional param');

done_testing;
