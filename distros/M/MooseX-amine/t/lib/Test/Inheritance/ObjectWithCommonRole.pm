package Test::Inheritance::ObjectWithCommonRole;
use Moose;
extends 'Test::Inheritance::BaseWithCommonRole';
with 'Test::Basic::Role','Test::Inheritance::CommonRole';
has 'string_attribute' => ( is => 'rw' , isa => 'Str' );
sub test_method { return 'this is a test' }
__PACKAGE__->meta->make_immutable;
1;
