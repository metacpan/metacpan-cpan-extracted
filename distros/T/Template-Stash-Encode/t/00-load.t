#!perl -T

use Test::Base;
plan tests => 1;

use_ok( 'Template::Stash::Encode' );

diag( "Testing Template::Stash::Encode $Template::Stash::Encode::VERSION, Perl $], $^X" );
