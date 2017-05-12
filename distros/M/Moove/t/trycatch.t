#!perl

use Test::Most;

plan tests => 10;

use_ok('t::TryCatch') or BAIL_OUT('');

lives_ok {
    like(t::TryCatch::test1() => qr'^abc\s*'s, 'test1');
} 'test1';

lives_ok {
    like(t::TryCatch::test2() => qr'^def\s*'s, 'test2');
} 'test2';

throws_ok {
    t::TryCatch::test3();
} qr'ghi\s*:\s*jkl\s*$'s;

lives_ok {
    like t::TryCatch::test4(123) => qr'^Int\[123 at .*]\s*$'s, 'Int[123]';
} 'test4 int';

lives_ok {
    like t::TryCatch::test4('abc') => qr'^Str\[abc at .*]\s*$'s, 'Str[abc]';
} 'test4 str';

done_testing;
