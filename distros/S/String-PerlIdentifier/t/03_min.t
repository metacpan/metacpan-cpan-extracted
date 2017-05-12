# t/03_min.t - test for correct failures due to bad arguments
use Test::More tests =>  31;
# qw(no_plan);
use strict;
use warnings;

BEGIN { use_ok( 'String::PerlIdentifier' ); }
use lib ("t/");
use Auxiliary qw{ _first_and_subsequent };

our (%eligibles, %chars);
require "t/eligible_chars";

my ($varname, $pattern);

four_basic_tests_min($_) for (2, 4..9);

eval { $varname = make_varname( { min => q<alphabetical> } ); };
$pattern = qq{Minimum must be all numerals};
like($@, qr/$pattern/, "use of non-numerals correctly fails");

eval { $varname = make_varname( { min => 1 } ); };
$pattern = qq{Cannot set minimum length less than 2};
like($@, qr/$pattern/, "attempt to set minimum less than 2 correctly fails");

##### SUBROUTINES #####

sub four_basic_tests_min {
    my $higher_min = shift;
    my $varname = make_varname( { min => $higher_min } );
    my $length = length($varname);
    ok( ($length >= $higher_min), 
        "length meets or exceeds $higher_min minimum");
    ok( ($length <= 20), "length meets or is less than maximum");
    
    _first_and_subsequent($varname);
}

