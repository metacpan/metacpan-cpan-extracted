package Local::MooRole2;

use Moo::Role;

with qw(Local::MooRole);

sub meth2 { 666 }

requires qw( req2 );

1;
