# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 4; # last test to print

BEGIN {
   use_ok('Template::Perlish');
}

my $tt = Template::Perlish->new();
ok($tt, 'object created');

{
   my $template = <<'END_OF_TEMPLATE';
Dear Customer,

   we are pleased to present you the following items:
[% for my $item (A) { %]
   * [%= $item %][%
   }
%]

Please consult our complete catalog.

Yours,

   The Director.
END_OF_TEMPLATE
   my $result = <<END_OF_TEMPLATE;
Dear Customer,

   we are pleased to present you the following items:

   * ciao
   * a
   * tutti
   * quanti

Please consult our complete catalog.

Yours,

   The Director.
END_OF_TEMPLATE
   my $processed = $tt->process($template,
      [ qw( ciao a tutti quanti ) ]);
   is($processed, $result, 'simple template with a block');
}

{
   my $got = Template::Perlish::render('[% 1.what.ever %]',
      [
         'foo',
         {
            what => { ever => 'bar', baz => 0 }
         },
         'anything goes',
      ]);
   my $expected = 'bar';
   is $got, $expected, 'another test with array input';
}
