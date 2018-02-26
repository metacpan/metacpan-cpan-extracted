#!/usr/bin/perl
#
use strict;
use warnings;
use Test::More tests => 9;

use_ok('Net::DNS::Extlang') || BAIL_OUT('failed to load Net::DNS::Extlang');


{					## default configuration
	my $default = new Net::DNS::Extlang();

	isnt( $default->domain, undef, '$default->domain' );	# TBD
	is( $default->file,	undef, '$default->file' );
	is( $default->lang,	'en',  '$default->lang' );
	is( $default->resolver, undef, '$default->resolver' );
}


{					## explicit configuration
	my $domain     = 'arbitrary.example.';
	my $file       = 't/rrtypes.txt';
	my $lang       = 'fr';
	my $resolver   = {qw(arbitrary reference)};
	my $configured = new Net::DNS::Extlang(
		domain	 => $domain,
		file	 => $file,
		lang	 => $lang,
		resolver => $resolver
		);

	is( $configured->domain,   $domain,   '$configured->domain' );
	is( $configured->file,	   $file,     '$configured->file' );
	is( $configured->lang,	   $lang,     '$configured->lang' );
	is( $configured->resolver, $resolver, '$configured->resolver' );
}


exit;

