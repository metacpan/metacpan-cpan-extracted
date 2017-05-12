package Local::MooClass2;

use Moo;

with qw(Local::MooseRole3);

sub req { 111 }

sub req2 { 222 };

1;
