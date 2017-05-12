package Test::Override::ObjectWithRole;
use Moose;
extends 'Test::Inheritance::Base';
with 'Test::Basic::Role';
has 'base_attribute' => ( is => 'rw' , isa => 'Str' );
has 'string_attribute' => ( is => 'rw' , isa => 'Str' );
has 'role_attribute' => ( is => 'ro' , isa => 'Int' );
sub role_method { return 'this is a test' }
sub base_method { return 'this is a test' }
sub test_method { return 'this is a test' }
__PACKAGE__->meta->make_immutable;
1;
