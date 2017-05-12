package Test::Inheritance::Object;
use Moose;
extends 'Test::Inheritance::Base';
has 'string_attribute' => ( is => 'rw' , isa => 'Str' );
sub test_method { return 'this is a test' }
__PACKAGE__->meta->make_immutable;
1;
