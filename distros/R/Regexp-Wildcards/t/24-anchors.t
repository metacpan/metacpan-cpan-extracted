#!perl -T

use strict;
use warnings;

use Test::More tests => 16;

use Regexp::Wildcards;

my $rw = Regexp::Wildcards->new(do => 'anchors');

is($rw->convert('\\^'),     '\\^',     'anchor: escape ^ 1');
is($rw->convert('\\\\\\^'), '\\\\\\^', 'anchor: escape ^ 2');
is($rw->convert('\\$'),     '\\$',     'anchor: escape $ 1');
is($rw->convert('\\\\\\$'), '\\\\\\$', 'anchor: escape $ 2');

is($rw->convert('^a?b*'),    '^a\\?b\\*',    'anchor: ^');
is($rw->convert('a?b*$'),    'a\\?b\\*$',    'anchor: $');
is($rw->convert('^a?b*$'),   '^a\\?b\\*$',   'anchor: ^$');
is($rw->convert('x^a?b*$y'), 'x^a\\?b\\*$y', 'anchor: intermediate ^$');

$rw->do(add => 'jokers');

is($rw->convert('^a?b*'),    '^a.b.*',   'anchor: ^ with jokers');
is($rw->convert('a?b*$'),    'a.b.*$',   'anchor: $ with jokers');
is($rw->convert('^a?b*$'),   '^a.b.*$',  'anchor: ^$ with jokers');
is($rw->convert('x^a?b*$y'), 'x^a.b.*$y','anchor: intermediate ^$ with jokers');

$rw->do(add => 'brackets');

is($rw->convert('{^,a}?b*'),    '(?:^|a).b.*',      'anchor: ^ with brackets');
is($rw->convert('a?{b*,$}'),    'a.(?:b.*|$)',      'anchor: $ with brackets');
is($rw->convert('{^a,?}{b,*$}'),'(?:^a|.)(?:b|.*$)','anchor: ^$ with brackets');
is($rw->convert('x{^,a}?b{*,$}y'), 'x(?:^|a).b(?:.*|$)y',
                                   'anchor: intermediate ^$ with brackets');
