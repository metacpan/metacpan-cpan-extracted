use strict;
use Test::More;
use Pandoc::Elements;
use Pandoc::Selector;

# test matching on elements
ok Str('')->match('Str'), 'match name';
ok !Str('')->match('Para'), 'no match';

ok Str('')->match('str'), 'case-insensitive';

ok Str('')->match(':inline'), 'type match';
ok !Str('')->match(':block'), 'type not match';

ok Str('')->match('str:inline'), 'multiple match';
ok Str('')->match('Foo|Str'), '| match';

ok !Str('')->match(Pandoc::Selector->new('#id')), 'no id match';

my $e = Code attributes { id => 'abc', class => ['f0_0','bar']} , '';

# test matching with selector
ok(Pandoc::Selector->new('#abc')->match($e), 'id match');
ok(!Pandoc::Selector->new('#xyz')->match($e), 'id no match');
ok(!Pandoc::Selector->new('#1')->match($e), 'id no match');

ok(Pandoc::Selector->new('.f0_0')->match($e), 'class match');
ok(Pandoc::Selector->new('.bar .f0_0')->match($e), 'classes match');
ok(!Pandoc::Selector->new('.xyz')->match($e), 'class no match');

ok $e->match("code\t:inline .bar#abc  .f0_0"), 'multiple match';

{
    my $plain = Plain [ Math InlineMath, 'x' ];
    is_deeply $plain->query(':inline'), $plain->content,
        ':inline match without keywords';
}

done_testing;
