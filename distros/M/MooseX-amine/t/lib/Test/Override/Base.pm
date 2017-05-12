package Test::Override::Base;
use Moose;
has 'base_attribute' => ( is => 'ro' , isa => 'Str' );
sub base_method  { return 'this is a test from the base' }
__PACKAGE__->meta->make_immutable;
1;
