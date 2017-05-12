#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;

use Test::More tests => 38;

use Regexp::English ':standard';

my $re = Regexp::English
	-> start_of_line()
	-> literal("1998/10/08")
	-> optional( Regexp::English::whitespace_char() )
	-> literal("[")
	-> remember( multiple( or( "-", Regexp::English::digit() ) ))
	-> non_digit();

ok( $re->match('1998/10/08 [11-10a'), 'should match basic regex' );
my ($match) = $re->match('1998/10/08 [11-10]');
ok( $match, 'match should capture, too' );
is( $match, '11-10', 'captured text should be okay' );
ok( ! $re->match('1999'), 'and it should not match bad data' );

$re = Regexp::English
	->start_of_line
	->remember( multiple( class( 'a-z' )));

ok( !( $re->match('1abcde') ), 'a character class should not match bad data' );
ok( $re->match('abcde'), 'but it should match good data' );

$re = Regexp::English
	->word_char
	->word_boundary
	->non_word_chars
	->very_end_of_string;

ok( $re->match('c$#'), 'test non_word_chars, boundary, very end' );
ok( !( $re->match('11') ), 'test non word, boundary, very end non-match' );

$re = Regexp::English
	->end_of_previous_match
	->tab
	->form_feed
	->alarm;

for (1 .. 2) {
	ok( $re->match("\t\f\a\t\f\a\t\f\a"), 'check \G, \t, \f, \a' );
}

$re = Regexp::English
	->remember( multiple( Regexp::English::digit() ))
	->remember( multiple( Regexp::English::whitespace_char() ))
	->remember( multiple( Regexp::English::word_char() ));

my @pieces = ('123', " \t\n", 'abc');
my @captures = $re->match(join('', @pieces, '!'));
for (0 .. 2) {
	is( $captures[$_], $pieces[$_], "test multiple captures ($_)" );
}

# poison the test
@captures = reverse @captures;
$re = Regexp::English
	->remember( \$captures[0], multiple( Regexp::English::digit() ))
	->remember( \$captures[1], multiple( Regexp::English::whitespace_char() ))
	->remember( \$captures[2], multiple( Regexp::English::word_char() ));

my @cap2 = $re->match(join('', @pieces, '!'));
for (0 .. 2) {
	is( $captures[$_], $pieces[$_], "test multiple captures to vars ($_)" );
}

for (0 .. 2) {
	is( $captures[$_], $cap2[$_], "test captured vars against returned ($_)" );
}

# test wantarray() support in capture()
my $cap = $re->match(join('', @pieces), '!');
is( $cap, $pieces[0], 'match() should respect scalar context with bound vars' );

$re = Regexp::English->new()
	->remember()
		->digits();

$cap = $re->match('abc123');
is( $cap, '123', 'match() should respect scalar context with no bound vars' );

$re = Regexp::English->new()
	->or( Regexp::English::digit, Regexp::English::word_char );

ok( $re->match('1'), 'should match first of alternate' );
ok( $re->match('a'), 'should match second of alternate' );
ok( ! $re->match(' '), 'should not match character not in alternation' );

$re = Regexp::English->new()
	->or( Regexp::English->digit, Regexp::English->word_char );

ok( $re->match('1'), 'alternate should work with class method calls' );
ok( $re->match('a'), '... and second alternate should also match' );
ok( ! $re->match(' '), '... and should not match bad match' );

my $scalar;
$re = Regexp::English->new
	->group
		->literal('abc')
	->end
	->remember(\$scalar)
		->literal('def');

ok( $re->match('abcdef!'), 'group() should work in pattern' );
is( $scalar, 'def', '... and should not interfere with other Groupings' );

$re = Regexp::English->new()
	->group
		->digit
	->or
		->word_char;

ok( $re->match('1'), 'should match first of alternate' );
ok( $re->match('a'), 'should match second of alternate' );
ok( ! $re->match(' '), 'should not match character not in alternation' );

$re = Regexp::English->new
	->remember
			->literal('root beer')
		->or
			->literal('milkshake')
	->end;

is( ($re->match('root beer float'))[0], 'root beer', 
	'or() should work when in a grouping' );
is( ($re->match('warmmilkshake'))[0], 'milkshake', '... matching both options');
ok( ! $re->match('beer in a can'), '... but not invalid match' );

$re = eval
{
	Regexp::English->new()
	->literal( 'foo' )
	->end()
};

like( $@, qr/end\(\) called without remember\(\)/,
	'end() should throw warning without remember() call' );

$re = Regexp::English->new()
	->literal( 'bar' )
	->multiple()
		->digit()
	->end();

is( $re->debug(), 'bar(?:\d+)', 'debug() should return built-up regexp' );

# test no-stack branch of compile()
$re = Regexp::English->new()
	->literal( 'baz' )
	->compile();

like( $re, qr/^\(\?[^:]+:baz\)$/, 'compile() should return compiled regexp' );
