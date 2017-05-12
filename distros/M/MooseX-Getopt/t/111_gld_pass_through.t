use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Getopt::Long::Descriptive;

use_ok('MooseX::Getopt::GLD');

{
    package Engine::Foo;
    use Moose;

    with 'MooseX::Getopt::GLD' => { getopt_conf => [ 'pass_through' ] };

    has 'foo' => (
        is          => 'ro',
        isa         => 'Int',
    );
}

{
    package Engine::Bar;
    use Moose;

    with 'MooseX::Getopt::GLD' => { getopt_conf => [ 'pass_through' ] };;

    has 'bar' => (
        is          => 'ro',
        isa         => 'Int',
    );
}

local @ARGV = ('--foo=10', '--bar=42');

{
    my $foo = Engine::Foo->new_with_options();
    isa_ok($foo, 'Engine::Foo');
    is($foo->foo, 10, '... got the right value (10)');
}

{
    my $bar = Engine::Bar->new_with_options();
    isa_ok($bar, 'Engine::Bar');
    is($bar->bar, 42, '... got the right value (42)');
}

done_testing;
