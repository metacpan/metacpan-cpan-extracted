#!/usr/bin/perl -w

BEGIN {
	chdir 't' if -d 't';
	push @INC, '../blib/lib';
}

use Test::More tests => 3;
use_ok( Regexp::English );

my $re = Regexp::English
	->new
	->literal('a')
	->followed_by('bc');

ok( $re->match('aabc'), 'followed_by should catch simple construct' );
ok( !($re->match('aab')), 'followed_by should not catch unmatching construct' );

# XXX:
#	test followed_by, not_followed_by, after, and not_after
$re = Regexp::English
	->new
	->remember(
		
	);
