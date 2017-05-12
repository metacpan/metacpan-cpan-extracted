#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::AttachmentFilter' );
}

diag( "Testing RT::Extension::AttachmentFilter $RT::Extension::AttachmentFilter::VERSION, Perl $], $^X" );
