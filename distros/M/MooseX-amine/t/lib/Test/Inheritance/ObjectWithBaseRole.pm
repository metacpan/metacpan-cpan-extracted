package Test::Inheritance::ObjectWithBaseRole;
use Moose;
extends 'Test::Inheritance::BaseWithRole';
has 'string_attribute' => ( is => 'rw' , isa => 'Str' );
sub test_method { return 'this is a test' }
__PACKAGE__->meta->make_immutable;
1;
