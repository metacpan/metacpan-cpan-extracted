package Local::MooClass;

use Moo;

with qw(Local::MooRole2);

sub req { 111 }

sub req2 { 222 };

1;
