package Local::MooRole3;

use Moo::Role;

with qw(Local::MooseRole);

sub meth2 { 666 }

requires qw( req2 );

1;
