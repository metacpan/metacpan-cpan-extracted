# vim: filetype=perl :
use strict;
use warnings;

use Test::More;    # tests => 4; # last test to print
use Template::Perlish qw< render >;

{
   my $data = {
      foo => 'bar',
      baz => {
         inner => 'stuff',
         also  => [qw< one array >],
      },
      frotz => {
         one   => 'two',
         three => 'four',
      }
   };

   my @tests = (
      ['[%= V "baz.also.1" %]',               'array',      'V()'],
      ['[%= join("-", A "baz.also") %]',      'one-array',  'A()'],
      ['[%= join("-", sort(HK("baz"))) %]',   'also-inner', 'HK()'],
      ['[%= join("-", sort(HV("frotz"))) %]', 'four-two',   'HV()'],
      [
         '[%= my %h = H "frotz"; join("-", sort(keys(%h))) %]',
         'one-three', 'H()'
      ],
   );

   for my $spec (@tests) {
      my ($template, $expected, $message) = @$spec;
      my $got = render($template, $data);
      is $got, $expected, $message;
   }
}

{
   my $data = {
      foo => 'bar',
      baz => {
         inner => 'stuff',
         also  => [qw< one array >],
      },
      frotz => {
         one   => 'two',
         three => 'four',
      }
   };

   my @tests = (
      ['[%= V "baz.also.1", V "i" %]',               'array',      'V()'],
      ['[%= join("-", A "baz.also", V "i") %]',      'one-array',  'A()'],
      ['[%= join("-", sort(HK("baz", V "i"))) %]',   'also-inner', 'HK()'],
      ['[%= join("-", sort(HV("frotz", V "i"))) %]', 'four-two',   'HV()'],
      [
         '[%= my %h = H "frotz", V "i"; join("-", sort(keys(%h))) %]',
         'one-three', 'H()'
      ],
   );

   for my $spec (@tests) {
      my ($template, $expected, $message) = @$spec;
      my $got = render($template, { i => $data });
      is $got, $expected, "$message - custom input data";
   }
}

done_testing();
