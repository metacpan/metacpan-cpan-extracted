BEGIN {
	chdir 't' if -d 't';
	push @INC, '../blib/lib';
}

use strict;
use Test::More tests => 11;

use Regexp::English qw( :standard );

my $re = Regexp::English
	->new
	->zero_or_more('a');

ok( $re->match(''), 'does zero or more match nothing?' );
ok( $re->match('aaaaaaabcd'), 'does zero or more match many?' );
ok( $re->match('bcdaaaaa'), 'does zero or more match anywhere?' );

$re = Regexp::English
	->new
	->multiple('a');

ok( !( $re->match('') ), 'does multiple not match nothing?' );
ok( $re->match('aaaaabcd'), 'does multiple match many?' );
ok( $re->match('bcdaaaa'), 'does multiple match anywhere?' );

$re = Regexp::English
	->new
	->minimal( multiple('a') )
	->literal('a');

ok( $re->match('abaa'), 'does minimal match?' );

$re = Regexp::English->new
	->optional('a');

ok( $re->match(''), 'does optional really mean optional?' );
ok( $re->match('b'), 'are you SURE?' );

$re = Regexp::English->new
	->remember
	->multiple
	->digit
	->end(2)
	->optional
	->whitespace_char;

my @matches;
ok( @matches = $re->match("123\t\r"), 'do empty quantifiers work?');
is( $matches[0], '123', 'do they grab the right thing?');
