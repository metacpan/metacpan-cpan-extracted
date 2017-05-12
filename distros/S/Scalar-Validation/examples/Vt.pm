# Perl
#
# Example of Scalar::Validation
#
# Catch validation trouble outside of this package
#
# Ralf Peine, Sat Jul 12 12:49:47 2014

$VERSION = "0.100";

use strict;
use warnings;

package Vt;

use Scalar::Validation qw (:all);

sub position {
    # --- define and scan parameters ------------------------------
    my $x = validate (x => greater_than 4 => Float => shift);
    my $y = validate (y => greater_than 2 => Float => shift);
    
    # --- something left in parameters ? ---
    parameters_end \@_;

    # --- run sub -------------------------------------------------
    print "int position ($x, $y)\n";
}

1;

