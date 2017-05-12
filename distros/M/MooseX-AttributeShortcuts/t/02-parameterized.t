use strict;
use warnings;

{
    package TestClass::WriterPrefix;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts -writer_prefix => '_';

    has foo => (is => 'rwp');
    has bar => (is => 'ro', builder => 1);
    has baz => (is => 'rwp', builder => 1);

}
{
    package TestClass::BuilderPrefix;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts -builder_prefix => '_silly_';

    has foo => (is => 'rwp');
    has bar => (is => 'ro', builder => 1);
    has baz => (is => 'rwp', builder => 1);

}

use Test::More;
use Test::Moose;

require 't/funcs.pm' unless eval { require funcs };

with_immutable { test_class('TestClass::WriterPrefix', '_') } 'TestClass::WriterPrefix';
with_immutable { test_class('TestClass::BuilderPrefix', undef, '_silly_') } 'TestClass::BuilderPrefix';

done_testing;

