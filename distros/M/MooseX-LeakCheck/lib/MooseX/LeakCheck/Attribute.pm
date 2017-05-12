package MooseX::LeakCheck::Attribute;
use Moose::Role;
use Moose::Util::TypeConstraints;

has leak_check => (
    is => 'ro',
);

1;
