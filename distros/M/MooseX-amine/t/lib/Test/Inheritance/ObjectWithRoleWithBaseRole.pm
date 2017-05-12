package Test::Inheritance::ObjectWithRoleWithBaseRole;
use Moose;
extends 'Test::Inheritance::BaseWithRole';
with 'Test::Basic::Role';
has 'string_attribute' => ( is => 'rw' , isa => 'Str' );
sub test_method { return 'this is a test' }
__PACKAGE__->meta->make_immutable;
1;
