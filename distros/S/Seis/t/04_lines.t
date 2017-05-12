use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is compile(q!"a\nb\n\nc".lines.join('|')!),   'a|b||c';
is compile(q!"a\nb\n\nc\n".lines.join('|')!), 'a|b||c', '.lines with trailing \n';
is compile(q!"a\nb\n\nc\n".lines(2).join('|')!), 'a|b', '.lines with limit';
is compile(q!lines("a\nb\nc\n").join('|')!), 'a|b|c',   '&lines';

done_testing;

