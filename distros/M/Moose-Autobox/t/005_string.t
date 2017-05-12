use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

use Moose::Autobox;

my $VAR1; # for eval of dumps

is('Hello World'->lc, 'hello world', '... $str->lc');
is('Hello World'->uc, 'HELLO WORLD', '... $str->uc');

is('foo'->ucfirst, 'Foo', '... $str->ucfirst');
is('Foo'->lcfirst, 'foo', '... $str->lcfirst');

dies_ok { ('Hello')->chop } '... cannot modify a read-only';
{
    my $greeting = 'Hello';
    is($greeting->chop, 'o', '... got the chopped off portion of the string');
    is($greeting, 'Hell', '... and are left with the rest of the string');
}

dies_ok { "Hello\n"->chomp } '... cannot modify a read-only';
{
    my $greeting = "Hello\n";
    is($greeting->chomp, '1', '... got the chopped off portion of the string');
    is($greeting, 'Hello', '... and are left with the rest of the string');
}

is('reverse'->reverse, 'esrever', '... got the string reversal');
is('length'->length, 6, '... got the string length');

is('Hello World'->index('World'), 6, '... got the correct index');

is('Hello World, Hello'->index('Hello'), 0, '... got the correct index');

is('Hello World, Hello'->index('Hello', 6), 13, '... got the correct index');

is('Hello World, Hello'->rindex('Hello'), 13, '... got the correct right index');

is('Hello World, Hello'->rindex('Hello', 6), 0, '... got the correct right index');

is_deeply('/foo/bar/baz'->split('/'), ['', 'foo', 'bar', 'baz'], '... got the correct fragments');
is_deeply('Hello World'->words, ['Hello', 'World'], '... got the correct words');
is_deeply("Hello\nWor\n\nld\n"->lines, ['Hello', 'Wor', '', 'ld'], '... got the correct lines');

eval 'Hello World, Hello'->dump;
is($VAR1, 'Hello World, Hello' , '... eval of &dump works');

eval 'Hello World, Hello'->perl;
is($VAR1, 'Hello World, Hello' , '... eval of &perl works');

