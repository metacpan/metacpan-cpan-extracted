#!perl -T
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
use Test::More tests => 10;

BEGIN {
    use_ok( 'Robotics' );
    use_ok( 'Robotics::Tecan' );
}

diag( "Testing Robotics $Robotics::VERSION, Perl $], $^X" );

SKIP: { 
    skip "This test needs upgrading to latest API", 8
        if 1;

    Robotics::Tecan->simulate_enable();  # Turn on simulation ability

    # Query before simulator start -> expect fail only if no h/w connected
    my @connected_hardware = Robotics->query();
    if (@connected_hardware) {
        diag "# Found hardware, is it connected? if not this test fails\n";
    }

    SKIP2: { 
        # Do not continue to test simulator if we are on Win32 and hardware
        # is attached
        skip "Skipping simulation test since hardware is found", 8
            unless (-d '/cygdrive/c' && @connected_hardware);

        # Start simulator before running any methods
        push(@INC, "t");
        require "sim-tecan.pl";
         
        @connected_hardware = Robotics->query();
        isnt(@connected_hardware, (), "didnt find any hardware");
        diag( "Found: @connected_hardware");
        pass("hardware check");

        Robotics::Tecan->attach();

        # Stop Simulator
        diag( "Simulator attempting stop.");
        SimulateTecan::Shutdown();
        Robotics::Tecan->status();
        diag( "Simulator stopped.");
    }
}

1;

