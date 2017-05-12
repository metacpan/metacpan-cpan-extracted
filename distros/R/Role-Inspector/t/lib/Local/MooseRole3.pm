package Local::MooseRole3;

use Moose::Role;

with qw(Local::MooRole);

sub meth2 { 666 }

requires qw( req2 );

1;
