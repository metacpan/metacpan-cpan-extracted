#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::Filter::VisualTruncate' );
}

diag( "Testing Template::Plugin::Filter::VisualTruncate $Template::Plugin::Filter::VisualTruncate::VERSION, Perl $], $^X" );
