use strict;
use warnings;

{
    package TestClass;

    use Moose;
    use namespace::autoclean;

    has bar => (is => 'ro');
}
{
    package TestClassTwo;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    extends 'TestClass';

    has '+bar' => (traits => [Shortcuts], builder => 1);
    has foo => (is => 'rwp');
    has baz => (is => 'rwp', builder => 1);

}

use Test::More;
use Test::Moose;

require 't/funcs.pm' unless eval { require funcs };

with_immutable { test_class('TestClassTwo') } 'TestClass', 'TestClassTwo';

done_testing;

