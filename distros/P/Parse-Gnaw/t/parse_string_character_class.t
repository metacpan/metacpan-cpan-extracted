#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;


use Test::More;

plan tests => 2;


use lib 'lib';

use Parse::Gnaw;
use Parse::Gnaw::LinkedList;

# Testing out character class function "cc"


rule('t_vowel_p', 't', cc('aeiou'), 'p');


my $string;


$string=Parse::Gnaw::LinkedList->new('tip');
ok($string->parse('t_vowel_p'), "t_vowel_p should match tip");

$string=Parse::Gnaw::LinkedList->new('txp');

ok(not($string->parse('t_vowel_p')), "t_vowel_p should not match txp");


__DATA__


$VAR1 = [
          'cc',
          'aeiou',
          {
            'methodname' => 'cc',
            'filename' => 't/parse_intermediate_string_character_class.t',
            'hash_of_letters' => {
                                   'e' => 1,
                                   'u' => 1,
                                   'a' => 1,
                                   'o' => 1,
                                   'i' => 1
                                 },
            'linenum' => 23,
            'payload' => 'aeiou',
            'package' => 'main'
          }
        ];












