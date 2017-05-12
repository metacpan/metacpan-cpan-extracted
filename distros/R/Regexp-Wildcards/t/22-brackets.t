#!perl -T

use strict;
use warnings;

use Test::More tests => 27;

use Regexp::Wildcards;

my $rw = Regexp::Wildcards->new(qw<do brackets>);

is($rw->convert('a{b\\\\,c\\\\}d', 'jokers'), 'a\\{b\\\\\\,c\\\\\\}d','jokers');

is($rw->convert('a{b\\\\,c\\\\}d', 'sql'), 'a\\{b\\\\\\,c\\\\\\}d', 'sql');

is($rw->convert('a{b\\\\,c\\\\}d', 'win32'), '(?:a\\{b\\\\|c\\\\\\}d)','win32');

is($rw->convert('{}'), '(?:)', 'empty brackets');
is($rw->convert('{a}'), '(?:a)', 'brackets 1');
is($rw->convert('{a,b}'), '(?:a|b)', 'brackets 2');
is($rw->convert('{a,b,c}'), '(?:a|b|c)', 'brackets 3');

is($rw->convert('a{b,c}d'), 'a(?:b|c)d',
   '1 bracketed block');
is($rw->convert('a{b,c}d{e,,f}'), 'a(?:b|c)d(?:e||f)',
   '2 bracketed blocks');
is($rw->convert('a{b,c}d{e,,f}{g,h,}'), 'a(?:b|c)d(?:e||f)(?:g|h|)',
   '3 bracketed blocks');

is($rw->convert('{a{b}}'), '(?:a(?:b))',
   '2 nested bracketed blocks 1');
is($rw->convert('{a,{b},c}'), '(?:a|(?:b)|c)',
   '2 nested bracketed blocks 2');
is($rw->convert('{a,{b{d}e},c}'), '(?:a|(?:b(?:d)e)|c)',
   '3 nested bracketed blocks');
is($rw->convert('{a,{b{d{}}e,f,,},c}'), '(?:a|(?:b(?:d(?:))e|f||)|c)',
   '4 nested bracketed blocks');
is($rw->convert('{a,{b{d{}}e,f,,},c}{,g{{}h,i}}'), '(?:a|(?:b(?:d(?:))e|f||)|c)(?:|g(?:(?:)h|i))',
   '4+3 nested bracketed blocks');

is($rw->convert('\\{\\\\}'), '\\{\\\\\\}',
   'escaping brackets');
is($rw->convert('\\{a,b,c\\\\\\}'), '\\{a\\,b\\,c\\\\\\}',
   'escaping commas 1');
is($rw->convert('\\{a\\\\,b\\,c}'), '\\{a\\\\\\,b\\,c\\}',
   'escaping commas 2');
is($rw->convert('\\{a\\\\,b\\,c\\}'), '\\{a\\\\\\,b\\,c\\}',
   'escaping commas 3');
is($rw->convert('\\{a\\\\,b\\,c\\\\}'), '\\{a\\\\\\,b\\,c\\\\\\}',
   'escaping brackets and commas');

is($rw->convert('{a\\},b\\{,c}'), '(?:a\\}|b\\{|c)',
   'overlapping brackets');
is($rw->convert('{a\\{b,c}d,e}'), '(?:a\\{b|c)d\\,e\\}',
   'partial unbalanced catching 1');
is($rw->convert('{a\\{\\\\}b,c\\\\}'), '(?:a\\{\\\\)b\\,c\\\\\\}',
   'partial unbalanced catching 2');
is($rw->convert('{a{b,c\\}d,e}'), '\\{a\\{b\\,c\\}d\\,e\\}',
   'no partial unbalanced catching');
is($rw->convert('{a,\\{,\\},b}'), '(?:a|\\{|\\}|b)',
   'substituting commas 1');
is($rw->convert('{a,\\{d,e,,\\}b,c}'), '(?:a|\\{d|e||\\}b|c)',
   'substituting commas 2');
is($rw->convert('{a,\\{d,e,,\\}b,c}\\\\{f,g,h,i}'), '(?:a|\\{d|e||\\}b|c)\\\\(?:f|g|h|i)',
   'handling the rest');
