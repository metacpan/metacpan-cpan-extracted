package Test::Basic::ObjectWithRole;
use Moose;
with 'Test::Basic::Role';
has 'simple_ro_attribute' => ( is => 'ro' , isa => 'Str' );
sub simple_method  { return 'simple' }
__PACKAGE__->meta->make_immutable;
1;
