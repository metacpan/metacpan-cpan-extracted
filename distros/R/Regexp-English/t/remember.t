#!/usr/bin/perl -w

BEGIN {
	chdir 't' if -d 't';
	push @INC, '../blib/lib';
}

use strict;
use Test::More tests => 14;

use_ok( 'Regexp::English', ':standard' );

my $re = Regexp::English->new()
	->digit
	->remember( multiple('a') )
	->word_char;

is( ($re->match('1aaab'))[0], 'aaa', 'remember() should return captured match');

$re = Regexp::English->new
	->digit
	->remember
	->multiple('a')
	->end
	->word_char;

is( ($re->match('1aaab'))[0], 'aaa', 'remember() and end() should also work' );

my ($first, $second);
$re = Regexp::English->new
	->digit
	->remember(\$first)
	->remember(\$second)
	->multiple('a')
	->end
	->word_char;

ok( $re->match('1aaab'), 'match() should handle nested remember()s' );
is( $first, 'aaab', 'remember/end should capture to variable fine' );

$re = Regexp::English->new
	->remember(\$first)
		->multiple('a')
		->remember(\$second)
			->word_char;

my @matches = qw( aaab aac ad );
my @expect = qw( b c d );
for (0 .. 2) {
	ok( $re->match( $matches[$_] ), 'should match matchable pattern' );
	is( $first, $matches[$_], 'should capture complete bound pattern' );
	is( $second, $expect[$_], 'should capture proper bound subpattern' );
}
