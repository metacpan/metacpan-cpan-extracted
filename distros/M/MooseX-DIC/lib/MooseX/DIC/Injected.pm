package MooseX::DIC::Injected;

use Moose::Role;
Moose::Util::meta_attribute_alias('Injected');

use MooseX::DIC::Types;

has scope => ( is => 'ro', isa => 'InjectionScope', default => 'object' );
has qualifiers =>
    ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] } );

1;
