#
# This file is part of Padre::Plugin::Template
# 

use Test::More tests => 2;
use Padre;
use Padre::Plugin::Shell::Base;

diag "Padre: $Padre::VERSION";
diag "Wx Version: $Wx::VERSION " . Wx::wxVERSION_STRING();

BEGIN {
    use_ok( 'Padre::Plugin::Template' );
    use_ok( 'Padre::Plugin::Shell::Template' );
}

diag( "Testing Padre::Plugin::Template $Padre::Plugin::Template::VERSION, Perl $], $^X" );
