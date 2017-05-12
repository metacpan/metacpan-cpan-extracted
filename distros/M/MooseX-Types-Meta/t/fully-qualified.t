use strict;
use warnings;

use Test::More;

use Class::MOP;
use Class::MOP::Class ();
use MooseX::Types::Meta 'Class';

my $c = Class::MOP::Class->initialize('Foo');
ok(is_Class(Class::MOP::Class->create('Foo')), 'is_Class');

ok(Class->isa('Moose::Meta::TypeConstraint'), 'type is available as an import');

ok(MooseX::Types::Meta::Class->isa('Moose::Meta::TypeConstraint'), 'type is available as a fully-qualified name');

done_testing;
