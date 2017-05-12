#!/usr/bin/perl -w

BEGIN {
	chdir 't' if -d 't';
	push @INC, '../blib/lib';
}

use strict;

use Test::More tests => 19;

use Regexp::English qw( :all );

my $re = Regexp::English
	-> start_of_line()
	-> literal("1998/10/08")
	-> optional( whitespace_char() )
	-> literal("[")
	-> remember( multiple( or( "-", digit() ) ))
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
	->remember( multiple( digit() ))
	->remember( multiple( whitespace_char() ))
	->remember( multiple( word_char() ));

my @pieces = ('123', " \t\n", 'abc');
my @captures = $re->match(join('', @pieces, '!'));
for (0 .. 2) {
	is( $captures[$_], $pieces[$_], "test multiple captures ($_)" );
}

# poison the test
@captures = reverse @captures;
$re = Regexp::English
	->remember( \$captures[0], multiple( digit() ))
	->remember( \$captures[1], multiple( whitespace_char() ))
	->remember( \$captures[2], multiple( word_char() ));

my @cap2 = $re->match(join('', @pieces, '!'));
for (0 .. 2) {
	is( $captures[$_], $pieces[$_], "test multiple captures to vars ($_)" );
}

for (0 .. 2) {
	is( $captures[$_], $cap2[$_], "test captured vars against returned ($_)" );
}

# XXX:
#	test and, or, not
#	test compile, debug
