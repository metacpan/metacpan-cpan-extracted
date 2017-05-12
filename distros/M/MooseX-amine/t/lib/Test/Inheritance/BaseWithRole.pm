package Test::Inheritance::BaseWithRole;
use Moose;
with 'Test::Basic::Role';
has 'base_attribute' => ( is => 'ro' , isa => 'Str' );
sub base_method  { return 'this is a test from the base' }
__PACKAGE__->meta->make_immutable;
1;
