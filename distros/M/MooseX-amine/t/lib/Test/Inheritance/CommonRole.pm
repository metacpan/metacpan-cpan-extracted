package Test::Inheritance::CommonRole;
use Moose::Role;
has 'common_role_attribute' => ( is => 'rw' , isa => 'Int' , default => 1 , documentation => 'this is some test documentation' );
sub common_role_method { return 'this is the role' }
1;
