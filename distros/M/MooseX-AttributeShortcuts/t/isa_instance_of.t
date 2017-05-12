use strict;
use warnings;

{
    package TestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    has bar => (is => 'ro',  isa_instance_of => 'SomeClass');
}

use Test::More;
use Test::Moose::More;

# TODO shift the constraint checking out into TMM?

validate_class TestClass => (
    attributes => [ qw{ bar } ],
);

subtest 'isa_instance_of check' => sub {
    my $att = 'bar';
    my $meta = TestClass->meta->get_attribute($att);
    ok $meta->has_type_constraint, "$att has a type constraint";
    my $tc = $meta->type_constraint;
    isa_ok $tc, 'Moose::Meta::TypeConstraint::Class';
    is $tc->class, 'SomeClass', 'tc looks for correct class';
};

done_testing;
