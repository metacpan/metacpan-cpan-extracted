#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

my @warnings;
BEGIN {
   $SIG{__WARN__} = sub {
      push @warnings, $_[0];
      print(STDERR $_[0]);
   };
}

BEGIN { require Syntax::Feature::Void; }


sub void { $_[0] }

my $rv = void("func");
is($rv, "func", "Inactive on load");

{
   use syntax qw( void );
   no warnings 'void';
   my $rv = void("keyword");
   is($rv, undef, "Active on 'use'");

   {
      no syntax qw( void );
      use warnings 'void';
      my $rv = void("func");
      is($rv, "func", "Inactive on 'no'");
   }

   $rv = void("keyword");
   is($rv, undef, "'no' lexically scopped");
}

$rv = void("func");
is($rv, "func", "'use' lexically scopped");

ok(!@warnings, "no warnings");
