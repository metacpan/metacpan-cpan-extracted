#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

my @warnings;
BEGIN {
   $SIG{__WARN__} = sub {
      push @warnings, $_[0];
      print(STDERR $_[0]);
   };
}

use syntax qw( void );

sub data {
   my @x = qw( a b c );
   return @x;
}

{
   my @rv = sub { data() }->();
   is(0+@rv, 3, "baseline");
}

{
   my @rv = sub { void(data()) }->();
   is(0+@rv, 0, "With parens");
}

{
   my @rv = sub { void data() }->();
   is(0+@rv, 0, "Without parens");
}

ok(!@warnings, "no warnings");
