use strict;
use warnings;

{
    package TestRole;

    use Moose::Role;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    has foo => (is => 'rwp');
    has bar => (is => 'ro', builder => 1);
}
{
    package TestClassTwo;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    with 'TestRole';

    has baz => (is => 'rwp', builder => 1);

}

use Test::More;
use Test::Moose;

use lib 't';
require funcs;

with_immutable {
    test_class('TestClassTwo');
} 'TestClassTwo';

done_testing;

