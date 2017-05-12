use strict;
use Test::More;
use Pandoc::Elements;

ok Str('')->match('Str'), 'match name';
ok !Str('')->match('Para'), 'no match';

ok Str('')->match('str'), 'case-insensitive';

ok Str('')->match(':inline'), 'type match';
ok !Str('')->match(':block'), 'type not match';

ok Str('')->match('str:inline'), 'multiple match';
ok Str('')->match('Foo|Str'), '| match';

ok !Str('')->match('#id'), 'no id match';

my $e = Code attributes { id => 'abc', class => ['f0.0','bar']} , '';

ok $e->match('#abc'), 'id match';
ok !$e->match('#xyz'), 'id no match';
ok !$e->match('#1'), 'id no match';

ok $e->match('.f0.0'), 'class match';
ok $e->match('.bar .f0.0'), 'classes match';
ok !$e->match('.xyz'), 'class no match';

ok $e->match("code\t:inline .bar#abc  .f0.0"), 'multiple match';

done_testing;
