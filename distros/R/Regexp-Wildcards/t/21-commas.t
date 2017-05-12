#!perl -T

use strict;
use warnings;

use Test::More tests => 8;

use Regexp::Wildcards;

my $rw = Regexp::Wildcards->new(); # unix

is($rw->convert('a,b,c'), 'a\\,b\\,c', 'unix: commas outside of brackets 1');
is($rw->convert('a\\,b\\\\\\,c'), 'a\\,b\\\\\\,c',
   'unix: commas outside of brackets 2');
is($rw->convert(',a,b,c\\\\,'), '\\,a\\,b\\,c\\\\\\,',
   'unix: commas outside of brackets at begin/end');

$rw = Regexp::Wildcards->new(type => 'commas');

is($rw->convert('a,b\\\\,c'), '(?:a|b\\\\|c)', 'win32: commas');
is($rw->convert('a\\,b\\\\,c'), '(?:a\\,b\\\\|c)', 'win32: escaped commas 1');
is($rw->convert('a\\,b\\\\\\,c'), 'a\\,b\\\\\\,c', 'win32: escaped commas 2');

is($rw->convert(',a,b\\\\,'), '(?:|a|b\\\\|)', 'win32: commas at begin/end');
is($rw->convert('\\,a,b\\\\\\,'), '(?:\\,a|b\\\\\\,)',
   'win32: escaped commas at begin/end');
