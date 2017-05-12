package Local::MooseRole2;

use Moose::Role;

with qw(Local::MooseRole);

sub meth2 { 666 }

requires qw( req2 );

1;
