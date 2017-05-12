# t/04_max.t - test for correct failures due to bad arguments
use Test::More tests => 114;
# qw(no_plan);
use strict;
use warnings;

BEGIN { use_ok( 'String::PerlIdentifier' ); }
use lib ("t/");
use Auxiliary qw{ _first_and_subsequent };

our (%eligibles, %chars);
require "t/eligible_chars";

my ($varname, $pattern, $length);

four_basic_tests_max($_) for (3..19,21..30);

eval { $varname = make_varname( { max => q<alphabetical> } ); };
$pattern = qq{Maximum must be all numerals};
like($@, qr/$pattern/, "use of non-numerals correctly fails");

eval { $varname = make_varname( { max => 2 } ); };
$pattern = qq{Cannot set maximum length less than 3};
like($@, qr/$pattern/, "attempt to set maximum less than 3 correctly fails");

eval { $varname = make_varname( { min => 12, max => 9 } ); };
$pattern = qq{Minimum must be <= Maximum};
like($@, qr/$pattern/, "minimum > maximum correctly fails");

$varname = make_varname( { min => 12, max => 19 } );
$length = length($varname);
ok( ($length == 12), "default < minimum is automatically corrected");

$varname = make_varname( { min =>  6, max =>  9 } );
$length = length($varname);
ok( ($length ==  9), "default > maximum is automatically corrected");

##### SUBROUTINES #####

sub four_basic_tests_max {
    my $max = shift;
    my $varname = make_varname( { max => $max } );
    my $length = length($varname);
    ok( ($length >= 3), "length meets or exceeds minimum");
    ok( ($length <= $max), "length meets or is less than $max maximum");
    
    _first_and_subsequent($varname);
}

