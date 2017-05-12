#!/usr/bin/perl -w

BEGIN {
	chdir 't' if -d 't';
	push @INC, '../blib/lib';
}

use strict;

use Test::More tests => 3;

# example 
	use Regexp::English;

	my $re = Regexp::English
		-> start_of_line
		-> literal('Flippers')
		-> literal(':')
		-> optional
			-> whitespace_char
		-> end
		-> remember
			-> multiple
				-> digit;
# example

ok( my $match = $re->match('Flippers: 123'), 'basic example should work' );
is( $match, '123', '... and should remember multiple digits' );

# now be very clever and match this example against Regexp::English itself
# though Inline::Tests handles this much more nicely

my $filepath = $INC{'Regexp/English.pm'};
local *MODULE;
my $module;
if (-e $filepath) {
	if (open(MODULE, $filepath)) {
		$module = do { local $/ = <MODULE> };
		$module =~ s/.+SYNOPSIS//s;
		$module =~ s/=head1.+//s;
		$module =~ tr/\t\n / /s;
	}
}

seek(DATA, 0, 0);
my $testfile = do { local $/; <DATA> };
$testfile =~ s/.+?# example/\t/s;
$testfile =~ s/# example.+//s;
$testfile =~ tr/\t\n / /s;
$testfile = quotemeta($testfile);

SKIP: {
	skip('Could not file Regexp::English file', 1) unless $module;
	like( $module, qr/$testfile/, 
		'test example should match the one in module' );
}

__DATA__
