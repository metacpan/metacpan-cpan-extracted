use strict;
use warnings;

use Test::More tests => 5;

my @warnings;
BEGIN {
   $SIG{__WARN__} = sub {
      push @warnings, $_[0];
      print(STDERR $_[0]);
   };
}

use syntax qw( loop );

#line 100
loop {
   is(__LINE__, 101);
   is(__LINE__, 102);
#line 110
   is(__LINE__, 110);
   last;
}
is(__LINE__, 113);

ok(!@warnings, "no warnings");

1;
