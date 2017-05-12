package Local::RoleTiny;

use Role::Tiny;

sub meth { 42 }

requires qw( req );

1;
