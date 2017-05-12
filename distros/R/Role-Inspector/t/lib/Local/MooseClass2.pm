package Local::MooseClass2;

use Moose;

with qw(Local::MooRole3);

sub req { 111 }

sub req2 { 222 };

1;
