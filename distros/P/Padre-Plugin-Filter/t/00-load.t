#
# This file is part of Padre::Plugin::Filter
# 

use Test::More tests => 2;
use Padre;
use Padre::Plugin::Shell::Base;

diag "Padre: $Padre::VERSION";
diag "Wx Version: $Wx::VERSION " . Wx::wxVERSION_STRING();

BEGIN {
    use_ok( 'Padre::Plugin::Filter' );
    use_ok( 'Padre::Plugin::Shell::Filter' );
}

diag( "Testing Padre::Plugin::Filter $Padre::Plugin::Filter::VERSION, Perl $], $^X" );
