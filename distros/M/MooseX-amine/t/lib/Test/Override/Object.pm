package Test::Override::Object;
use Moose;
extends 'Test::Inheritance::Base';
has 'base_attribute' => ( is => 'rw' , isa => 'Str' );
has 'string_attribute' => ( is => 'rw' , isa => 'Str' );
sub base_method { return 'this is a test' }
sub test_method { return 'this is a test' }
__PACKAGE__->meta->make_immutable;
1;
