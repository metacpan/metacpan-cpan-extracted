package Local::MouseClass;

use Mouse;

with qw(Local::MouseRole2);

sub req { 111 }

sub req2 { 222 };

1;
