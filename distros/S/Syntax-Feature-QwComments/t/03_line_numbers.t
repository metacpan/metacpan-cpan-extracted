use strict;
use warnings;

use Test::More tests => 3;

my @warnings;
BEGIN {
   $SIG{__WARN__} = sub {
      push @warnings, $_[0];
      print(STDERR $_[0]);
   };
}

use syntax qw( qw_comments );

my @a;

#line 1
@a = qw(
   a
   b
);
is(__LINE__, 5, "Newlines in qw()");

#line 1
@a = qw(
   a
#line 1
   b
);
is(__LINE__, 3, "#line in qw()");

ok(!@warnings, "no warnings");

1;
