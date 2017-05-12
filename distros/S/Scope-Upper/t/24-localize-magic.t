#!perl -T

use strict;
use warnings;

use Scope::Upper qw<localize UP HERE>;

use Test::More tests => 5;

my @a = qw<a b c>;

{
 local $" = '';
 {
  localize '$"', '_' => HERE;
  is "@a", 'a_b_c', 'localize $" => HERE [ok]';
 }
 is "@a", 'abc', 'localize $" => HERE [end]';
}

{
 local $" = '';
 {
  local $" = '-';
  {
   localize '$"', '_' => UP;
   is "@a", 'a-b-c', 'localize $" => UP [not yet]';
  }
  is "@a", 'a_b_c', 'localize $" => UP [ok]';
 }
 is "@a", 'abc', 'localize $" => UP [end]';
}
