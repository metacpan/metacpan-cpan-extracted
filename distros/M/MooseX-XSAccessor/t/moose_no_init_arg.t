use lib "t/lib";
use lib "moose/lib";
use lib "lib";

## skip Test::Tabs

use strict;
use warnings;

use Test::More;



{
    package Foo;
    use MyMoose;

    eval {
        has 'foo' => (
            is => "rw",
            init_arg => undef,
        );
    };
    ::ok(!$@, '... created the attr okay');
}

{
    my $foo = Foo->new( foo => "bar" );
    isa_ok($foo, 'Foo');

    is( $foo->foo, undef, "field is not set via init arg" );

    $foo->foo("blah");

    is( $foo->foo, "blah", "field is set via setter" );
}

done_testing;
