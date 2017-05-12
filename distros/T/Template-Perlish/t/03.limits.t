# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 34; # last test to print

BEGIN {
   use_ok('Template::Perlish');
}

my $tt = Template::Perlish->new();
ok($tt, 'object created');

my %vars = (
   name     => 'ilnome',
   sname    => 'ilcognome',
   whatever => 'you do',
   do       => 'it well',
);

my %case_for = (
   'empty'                => ['',                      ''],
   'only one variable'    => ['[% sname %]',           'ilcognome',],
   'only one block'       => ['[% print "ciao\n"; %]', "ciao\n",],
   'ending with variable' => [
      "yadda yadda\n yadda\n  blash[% name %]",
      "yadda yadda\n yadda\n  blashilnome",
   ],
   'ending with block' => [
      "whateee\n\n\eeever\n  [% print \"ciao\\n\"; %]",
      "whateee\n\n\eeever\n  ciao\n",
   ],
   'starting with variable' =>
     ["[% name %] whatever\n\nafter", "ilnome whatever\n\nafter",],
   'starting with block' => [
      "[% print \"ciao\\n\"; %] whatever\n\nafter",
      "ciao\n whatever\n\nafter",
   ],
   'weird empty block' => [
      '[[%%]%', '[%',
   ],
);

my $some_spaces = "  \n \t \n\n ";
for my $name (keys %case_for) {
   my ($template, $expected) = @{$case_for{$name}};
   my $got = $tt->process($template, \%vars);
   is($got, $expected, 'template: ' . $name);

   $expected = '' unless defined $expected;

   $got = $tt->process($some_spaces . $template, \%vars);
   is(
      $got,
      $some_spaces . $expected,
      'template: ' . $name . '(with spaces before)'
   );

   $got = $tt->process($template . $some_spaces, \%vars);
   is(
      $got,
      $expected . $some_spaces,
      'template: ' . $name . '(with spaces after)'
   );

   $got = $tt->process($some_spaces . $template . $some_spaces, \%vars);
   is(
      $got,
      $some_spaces . $expected . $some_spaces,
      'template: ' . $name . '(with spaces before and after)'
   );

} ## end for my $name (keys %case_for)
