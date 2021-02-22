package MooX::Role::Clone;
use Moo::Role;
use Clone ();

no warnings 'once';
*clone = \&Clone::clone;

1;