#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 11;

BEGIN { use_ok('Regex::Iterator') }

my $string = 'string to search';
my $re = qr/[aeiou]/i;

ok(my $i = new Regex::Iterator ($re, $string), 'new()');

is($i->string(), $string, 'string() returns string');
is($i->result(), $string, 'result() starts as string');
is($i->re(),     $re,     'get_re returns regexp');

while (my $vowel = $i->match) { $i->replace('o') }

is($i->result(), 'strong to soorch', "replaced all vowels with 'o'");

is($i->rewind(), $i, 'rewind()');

is($i->result(), $string, 'after rewind, $result == $string again');

$string = 'no match';
$re = 'foo';

ok(!eval {
  $i->string($string)
    ->re($re)
    ->match()
  },
  'chaining works'
);

is($i->string, $string,   'set string works');
is(ref($i->re),	"Regexp", 'set re works');



__END__

vim:ft=perl
