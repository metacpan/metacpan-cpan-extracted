package Test::Basic::ObjectOverridingRole;
use Moose;
with 'Test::Basic::Role';
has 'role_attribute' => ( is => 'rw' , isa => 'Int' ,
                          documentation => 'overridden attribute' );
sub role_method  { return 'override' }
__PACKAGE__->meta->make_immutable;
1;
