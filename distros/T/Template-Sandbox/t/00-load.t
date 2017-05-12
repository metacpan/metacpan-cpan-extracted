#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok( 'Template::Sandbox' );
    use_ok( 'Template::Sandbox::Library' );
    use_ok( 'Template::Sandbox::StringFunctions' );
    use_ok( 'Template::Sandbox::NumberFunctions' );
}

diag( "Testing Template::Sandbox $Template::Sandbox::VERSION, Perl $], $^X" );
