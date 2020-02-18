use strict;
use warnings;

use Test::Arrow;

my $got = my $expected = "same";
my $isnt_expected = 'wrong';

Test::Arrow->pass('PASS');

my $arr = Test::Arrow->new;

$arr->pass('PASS2');

# ok
$arr->ok($got);
$arr->ok($got, 'ok1');
$arr->got($got)->ok;
$arr->name('ok2')->ok($got);
$arr->name('ok3')->ok($got, 'test name overwrite');

{
    $arr->got($got)->ok($got); # Warn duplicated $got
}

$arr->diag('diag message')->note('note message')->ok(1);
$arr->explain({ foo => 123 })->ok(1);

# to_be
$arr->expect($expected)->to_be($got);
$arr->name('to_be1')->expect($expected)->to_be($got);
$arr->expect($expected)->to_be($got, 'to_be2');

# is
$arr->is($got, $expected);
$arr->is($got, $expected, 'is1');
$arr->expected($expected)
    ->got($got)
    ->is;
$arr->name('is2')
    ->expected($expected)
    ->got($got)
    ->is;

$arr->name('expect alias')
    ->expect($expected)
    ->got($got)
    ->is;

$arr->name('expalin test')->expected($expected)->got($got)->explain->is;

# isnt
$arr->isnt($got, $isnt_expected);
$arr->isnt($got, $isnt_expected, 'isnt1');
$arr->expected($isnt_expected)
    ->got($got)
    ->isnt;
$arr->name('isnt2')
    ->expected($isnt_expected)
    ->got($got)
    ->isnt;

# is_num
$arr->is_num(123, 123);
$arr->is_num(123, 123, 'is_num1');
$arr->expected(123)
    ->got(123)
    ->is_num;
$arr->name('is_num2')
    ->expected(123)
    ->got(123)
    ->is_num;

# isnt_num
$arr->isnt_num(123, 1234);
$arr->isnt_num(123, 1234, 'isnt_num1');
$arr->expected(1234)
    ->got(123)
    ->isnt_num;
$arr->name('isnt_num2')
    ->expected(1234)
    ->got(123)
    ->isnt_num;

# like
$arr->like($got, qr/a/);
$arr->like($got, qr/a/, 'like1');
$arr->expected(qr/a/)
    ->got($got)
    ->like;
$arr->name('like2')
    ->expected(qr/a/)
    ->got($got)
    ->like;

{
    $arr->expected(qr/a/)->like($got, qr/a/); # Warn duplicated $expected
}

# unlike
$arr->unlike($got, qr/b/);
$arr->unlike($got, qr/b/, 'unlike1');
$arr->expected(qr/b/)
    ->got($got)
    ->unlike;
$arr->name('unlike2')
    ->expected(qr/b/)
    ->got($got)
    ->unlike;

$arr->done_testing;
