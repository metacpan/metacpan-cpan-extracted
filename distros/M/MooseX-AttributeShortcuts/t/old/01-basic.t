use strict;
use warnings;

{
    package TestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    has foo => (is => 'rwp');
    has bar => (is => 'ro', builder => 1);
    has baz => (is => 'rwp', builder => 1);

}

use Test::More;
use Test::Moose;

require 't/funcs.pm' unless eval { require funcs };

test_class('TestClass');

done_testing;
