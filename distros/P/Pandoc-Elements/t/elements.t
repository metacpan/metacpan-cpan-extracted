use strict;
use Test::More;
use Pandoc::Elements qw(Emph Str attributes element);
use JSON;

is_deeply [ Str 'hello' ], 
          [ { t => 'Str', c => 'hello' } ], 'Emph';
is_deeply [ Str 'hello', 'world' ], 
          [ { t => 'Str', c => 'hello' }, 'world' ], 'Emph';
is_deeply [ Emph Str 'hello' ], 
          [ { t => 'Emph', c => { t => 'Str', c => 'hello' } } ], 'Emph';

my $code = element( Code => attributes {}, 'x' );
is_deeply $code, { t => 'Code', c => [["",[],[]],"x"] }, 'element';
ok $code->is_inline, 'is_inline';
is_deeply $code->content, 'x', 'content';

eval { element ( Foo => 'bar' ) }; ok $@, 'unknown element';
eval { element ( Code => 'x' ) }; ok $@, 'wrong number of arguments';

is_deeply decode_json(Str('今日は')->to_json), 
    { t => 'Str', c => '今日は' }, 'method to_json';

my $ast = element ( Header => 6, attributes { foo => 6 }, Str 6 );
is_deeply [ $ast->to_json =~ /(.6.)/g ], [ '[6,', '"6"', '"6"',], 'stringify numbers';

done_testing;
