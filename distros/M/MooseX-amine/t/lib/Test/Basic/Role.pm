package Test::Basic::Role;
use Moose::Role;
has 'role_attribute' => ( is => 'rw' , isa => 'Str' , required => 1 ,
                            documentation => 'required string' );
sub role_method  { return 'role' }
1;
