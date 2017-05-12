package Local::MouseRole2;

use Mouse::Role;

with qw(Local::MouseRole);

sub meth2 { 666 }

requires qw( req2 );

1;
