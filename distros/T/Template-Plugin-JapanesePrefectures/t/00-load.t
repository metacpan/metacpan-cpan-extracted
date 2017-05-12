#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::JapanesePrefectures' );
}

diag( "Testing Template::Plugin::JapanesePrefectures $Template::Plugin::JapanesePrefectures::VERSION, Perl $], $^X" );
