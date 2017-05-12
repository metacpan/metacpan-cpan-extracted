use strict;
use warnings;

my $trigger_called = 0;

{
    package TestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    has foo => (is => 'rwp');
    has bar => (is => 'ro', builder => 1);
    has baz => (is => 'rwp', builder => 1);

    sub _build_bar {}
    sub _build_baz {}

    has fee => (is => 'rw', trigger => 1);
    sub _trigger_fee { $trigger_called++ }

    has _foe => (is => 'rw', trigger => 1);
    sub _trigger__foe { $trigger_called++ }
}

use Test::More;
use Test::Moose;

require 't/funcs.pm' unless eval { require funcs };

with_immutable {

    test_class('TestClass');

    for my $name (qw{ fee _foe }) {

        $trigger_called = 0;

        my $a = TestClass->meta->get_attribute($name);
        ok $a->has_trigger, "$name has a trigger";

        ok !$trigger_called, 'no trigger calls yet';
        my $tc = TestClass->new($name => 'Ian');
        is $trigger_called, 1, 'trigger called once';
        $tc->$name('Cormac');
        is $trigger_called, 2, 'trigger called again';

    }

} 'TestClass';

done_testing;

