package Local::MooseClass;

use Moose;

with qw(Local::MooseRole2);

sub req { 111 }

sub req2 { 222 };

1;
