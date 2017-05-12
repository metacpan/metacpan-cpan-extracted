use strict;
use warnings;
no warnings 'qw';

use Test::More tests => 6;

my @warnings;
BEGIN {
   $SIG{__WARN__} = sub {
      push @warnings, $_[0];
      print(STDERR $_[0]);
   };
}

BEGIN { require Syntax::Feature::QwComments; }

my @a;

@a = qw(
   a # b
);
is(join('|', @a), "a|#|b", "Inactive on load");

{
   use Syntax::Feature::QwComments;
   
   @a = qw(
      a # b
   );
   is(join('|', @a), "a", "Active on 'use'");
   
   {
      no Syntax::Feature::QwComments;
   
      @a = qw(
         a # b
      );
      is(join('|', @a), "a|#|b", "Inactive on 'no'");
   }
   
   @a = qw(
      a # b
   );
   is(join('|', @a), "a", "'no' lexically scopped");
}

@a = qw(
   a # b
);
is(join('|', @a), "a|#|b", "'use' lexically scopped");

ok(!@warnings, "no warnings");

1;
