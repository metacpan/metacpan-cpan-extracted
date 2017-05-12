package Local::RoleBasic2;

use Role::Basic;

with qw(Local::RoleBasic);

sub meth2 { 666 }

requires qw( req2 );

1;
