package Local::RoleBasic;

use Role::Basic;

sub meth { 42 }

requires qw( req );

1;
