#!/usr/bin/perl
use strict;
use warnings;

=pod

I had the bless() after a method call to _die. In older versions I called
Perl's die() so the location of the bless() didn't matter. Now it does.

Reported by Sagar Shah.

=cut

use Test::More 1.0;

require 't/lib/setup_common.pl';

my $class = 'Module::Release';
subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'new' );
	};

subtest remove_conf_files => sub {
	unlink '.releaserc';
	ok( ! (-e '.releaserc'), 'The .releaserc file is missing (good)' );

	unlink 'releaserc';
	ok( ! (-e 'releaserc'), 'The releaserc file is missing (good)' );
	};

subtest new => sub {
	ok( ! eval{ close STDERR; $class->new() }, 'new() does not die (good)' );

	like( $@, qr/Could not find conf file releaserc/,
		'Missing conf file dies with the right error message' );
	};

done_testing();
