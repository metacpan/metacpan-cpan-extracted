package Local::RoleTiny2;

use Role::Tiny;

with qw(Local::RoleTiny);

sub meth2 { 666 }

requires qw( req2 );

1;
