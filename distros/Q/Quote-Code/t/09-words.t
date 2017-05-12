use warnings FATAL => 'all';
use strict;

use Test::More tests => 16;

use Quote::Code;

my $foo = 'foo';
my $bar_baz = 'bar baz';
my $_quux_ = '{ quux }';

is_deeply [qcw\\], [qw\\];
is_deeply [qcw~        ~], [qw~ ~];
is_deeply [qcw'abc'], [qw'abc'];
is_deeply [qcw(a b c)], [qw(a b c)];
is_deeply [qcw[ xy ]], [qw[ xy ]];
is_deeply [qcw(foo\ bar\ baz)], ['foo bar baz'];
is_deeply [qcw( foo\ bar\t ba\nz )], ["foo bar\t", "ba\nz"];
is_deeply [qcw( 2 + 2 = { 2 + 2 } )], [qw( 2 + 2 = 4 )];
is_deeply [qcw( a{' '}b{"\n"}c\\ {"foo" . "bar"})], ["a b\nc\\", "foobar"];
is_deeply [qcw{$foo $bar $baz}], [qw{$foo $bar $baz}];
is_deeply [qcw{{$foo}{$bar_baz}{$_quux_}}], ["$foo$bar_baz$_quux_"];
is_deeply [qcw{ A{$foo} B{$bar_baz} {$_quux_}C }], ["A$foo", "B$bar_baz", "${_quux_}C"];
is_deeply [qcw'{$foo}\ \ {$bar_baz} #   
	{reverse "AB", $_quux_} '], ["$foo  $bar_baz", "#", scalar(reverse "AB", $_quux_)];
is __LINE__, 26;
is_deeply [qcw(foo (bar ba)z)], [qw(foo (bar ba)z)];
is_deeply [qcw(foo \(bar baz)], [qw(foo \(bar baz)];
