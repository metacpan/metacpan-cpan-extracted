#!perl -T
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
use Test::More tests => 8;


BEGIN {
    use_ok( 'Robotics' );
}

diag( "Testing Robotics $Robotics::VERSION, Perl $], $^X" );

SKIP: {
    # Only continue to test if we are on Win32 and hardware
    # is connected
    skip "No Win32 found, cant test hardware", 7
        unless ((-d '/cygdrive/c') || (-d '/Program Files'));

    SKIP2: { 
        skip "Must set environ var TECANPASSWORD for server password", 7
            unless ($ENV{'TECANPASSWORD'});

        my $obj = Robotics->new();
        print "Hardware: ". $obj->printDevices();
        my $gemini;
        my $hw;
        if ($gemini = $obj->findDevice(product => "Gemini")) { 
            print "Found local Gemini $gemini\n";
            pass("find tecan");
            my $genesis = $obj->findDevice(product => "Genesis");
            pass("find genesis");
        }
        else {
            print "No Gemini found\n";
            fail("find tecan");
            fail("find genesis");
            skip "No locally-connected hardware found, cant test", 5
                unless $gemini;
        }

         
        if (0) {
            # Found but gemini not started, complain
            diag "Skipping real hardware test since GEMINI not started\n";
            diag "(Experimental) Try to use Robotics::Tecan->startService() (see docs)\n";
            Robotics::Tecan->startService();

            # Call Robotics->new() again in case gemini now started
        }

        $hw = Robotics::Tecan->new(
            connection => $gemini);
        if ($hw) { 
            pass("new");
        }
        else {
            plan skip_all => "cant connect to tecan hardware";
        }

        if ($hw) {
            is($result = $hw->attach(), "0;Version 4.1.0.0", "attach");
            if (!$result) { 
                plan skip_all => "Skipping real hardware test since cant attach";
            }
            is($result = $hw->status(), "0;IDLE", "status");
            is($hw->server(password => $ENV{'TECANPASSWORD'}), 1, "server");
        }
    }
}


1;

