#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

use Config;
ok($Config{startperl}, 'initial state');

use Mock::Config;
# no lexical state yet, just dynamic
Mock::Config->import(startperl => '');
diag( "Testing Mock::Config, Perl $], ".
      (exists &Config::KEYS ? 'XS' : '')."Config $Config::VERSION, $^X" );

is($Config{startperl}, '', 'mocked to empty');

Mock::Config->unimport;
ok($Config{startperl}, 'reset');

