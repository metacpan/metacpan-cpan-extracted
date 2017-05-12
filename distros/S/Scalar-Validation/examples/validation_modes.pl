# Perl
#
# Example of Scalar::Validation, Select Validation modes
#
# perl run_modes.pl (die|warn|silent|off)
#
# Ralf Peine, Sat Jul 12 13:07:15 2014

$| = 1;

use strict;
use warnings;

use Scalar::Validation qw (:all);
use Vt;

sub position {
    Vt::position(@_);
}

my $validation_mode = shift || 'die';

{
    print "# - { - Start new block ================================\n";
    print "# ----- Switch to validation mode $validation_mode -----\n\n";

    local $Scalar::Validation::trouble_level = 0;
    local ($Scalar::Validation::fail_action, $Scalar::Validation::off)
	= prepare_validation_mode($validation_mode => 1);
    
    my $var = '0';
    
    print "'".ref('0')."'\n";
    
    position (5, 3);
    position (4.001, 2.001);
    
    
    position ('a4.1', 2);
    position ('a5', 2);

    position ();
    position (1);
    position (1, 2, 3);

    print "\n# ----- validation trouble in block:   ".validation_trouble()." -----\n";
    print "# - } - Leave block ======================================\n";
}

print "# validation trouble outside of block: ".validation_trouble()." -----\n";
print "\n# returning to initial validation mode: 'die'.\n";


position ('a4.1', 2); # dies

print "#### did not die!!!\n";
