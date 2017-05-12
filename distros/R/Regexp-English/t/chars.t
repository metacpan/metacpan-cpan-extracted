#!/usr/bin/perl -w

BEGIN {
	chdir 't' if -d 't';
	unshift @INC, '../blib/lib';
}

use strict;
use Test::More tests => 62;
use Regexp::English;

my $re = Regexp::English->new
	->word_char;

ok( $re->match('a'), 'match a word char' );
ok( !( $re->match('!') ), 'do not match a non word char' );

$re = Regexp::English->new
	->word_chars;

ok( $re->match('aaaa'), 'match muliple word chars' );
ok( $re->match('a'), 'match a single word char, looking for multiple' );
ok( !( $re->match('!') ), 'do not match a non word char' );

$re = Regexp::English->new
	->non_word_char;

ok( $re->match('!'), 'match a non word char' );
ok( !( $re->match('a') ), 'do not match a word char' );

$re = Regexp::English->new
	->non_word_chars;

ok( $re->match('!!!!!'), 'match multiple non word chars' );
ok( $re->match('!'), 'match a single non word char' );
ok( !( $re->match('a') ), 'do not match a word char' );

$re = Regexp::English->new
	->whitespace_char;

my $re2 = Regexp::English->new
	->non_whitespace_char;

for my $char ("\n", "\r", "\f", "\t", " ") {
	ok( $re->match($char), 'match whitespace char' );
	ok( !( $re2->match($char) ), 'do not match against non whitespace char' );
}

for my $char (qw( 1 a ! $ )) {
	ok( !( $re->match($char) ), 'do not match against non whitespace char' );
	ok( $re2->match($char), 'match whitespace char' );
}

$re = Regexp::English->new
	->digit;

$re2 = Regexp::English->new
	->non_digit;

for my $char (0 .. 1) {
	ok( $re->match($char), 'match against digit char' );
	ok( !( $re2->match($char) ), 'do not match against non digit char' );
}

for my $char ( "\n", 'a', '!', '"' ) {
	ok( !( $re->match($char) ), 'do not match against digit char' );
	ok( $re2->match($char), 'match against non digit char' );
}

$re = Regexp::English->new
	->word_boundary
	->digit
	->literal('a');

ok( $re->match('.1a'), 'match word boundary' );
ok( !( $re->match('11a') ), 'do not match non word boundary' );

$re = Regexp::English->new
	->word_char
	->end_of_string;

$re2 = Regexp::English->new
	->word_char
	->very_end_of_string;

ok( $re->match("a\n"), 'match end of string at newline' );
ok( !( $re2->match("a\n") ), 'do not match very end of string at newline' );
ok( $re->match('a'), 'match end of string without newline' );
ok( $re2->match('a'), 'match very end of string without newline' );

$re = Regexp::English->new
	->beginning_of_string
	->digit;

ok( $re->match('1'), 'match beginning of string' );
ok( !( $re->match('a1') ), 'do not match non beginning of string' );

# XXX:
#	this may be a bad test... shouldn't it be in a while loop?
$re = Regexp::English->new
	->end_of_previous_match
	->digit;

for (1 .. 3) {
	ok( $re->match('123'), 'match end of previous match' );
}

$re = Regexp::English->new
	->tab
	->newline
	->carriage_return
	->form_feed
	->alarm
	->escape;

$re2 = Regexp::English->new
	->escape
	->alarm
	->form_feed
	->carriage_return
	->newline
	->tab;

my $ws = "\t\n\r\f\a\e";
ok( $re->match($ws), 'match \t \n \r \f \a \e in order' );
ok( !( $re2->match($ws) ), 'do not match whitespace chars out of order' );

$ws = reverse($ws);
ok( !( $re->match($ws) ), 'do not match \e \a \f \r \n \t in order' );
ok( $re2->match($ws), 'match whitespace chars in order' );

$re = Regexp::English->new
	->start_of_line
	->word_chars;

ok( $re->match('abc'), 'match start of line' );
ok( !( $re->match('!abc') ), 'do not match unless at start of line' );

$re = Regexp::English->new
	->word_chars
	->end_of_line;

ok( $re->match('abc'), 'match end of line' );
ok( !( $re->match('abc ') ), 'do not match unless at end of line' );

$re = Regexp::English->new
	->tabs
	->remember
	->digits
	->end_of_string;

ok( !( $re->match("123")), 'should not match with no tabs');
ok( $re->match("\t123"), 'should match with one tab');
is( ($re->match("\t\t123"))[0], '123', 'should match with multiple tabs');
