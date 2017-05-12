package TestAttributeHelpers;
use Moose::Role;
use MooseX::AttributeHelpers;

has foo => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => 'ArrayRef[Int]',
    provides    => {
        count       => 'foo_count',
    },
);

1;
