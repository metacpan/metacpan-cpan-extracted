use strict;
use warnings;
use Test::More;

BEGIN {
    if (! $ENV{RPI_SUBMODULE_TESTING}){
        plan(skip_all => "RPI_SUBMODULE_TESTING environment variable not set");
    }

    if (! $ENV{RPI_MCP23017}){
        plan(skip_all => "Skipping: RPI_MCP23017 environment variable not set");
    }

    use_ok( 'RPi::GPIOExpander::MCP23017' ) || print "Bail out!\n";
}

diag( "Testing RPi::GPIOExpander::MCP23017 $RPi::GPIOExpander::MCP23017::VERSION, Perl $], $^X" );

done_testing();
