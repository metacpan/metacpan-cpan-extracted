# t/05_default.t - test for correct failures due to bad arguments
use Test::More tests =>  61;
# qw(no_plan);
use strict;
use warnings;

BEGIN { use_ok( 'String::PerlIdentifier' ); }
use lib ("t/");
use Auxiliary qw{ _first_and_subsequent };

our (%eligibles, %chars);
require "t/eligible_chars";

my ($varname, $pattern, $length);

two_basic_tests_default($_) for (3..20);

eval { $varname = make_varname( { default => q<alphabetical> } ); };
$pattern = qq{Default must be all numerals};
like($@, qr/$pattern/, "use of non-numerals correctly fails");

$varname = make_varname( { default => 2 } );
$length = length($varname);
ok( ($length == 3), "default < minimum is automatically corrected");

$varname = make_varname( { default => 21 } );
$length = length($varname);
ok( ($length == 20), "default > maximum is automatically corrected");

$varname = make_varname( { default => 12, min => 15 } );
$length = length($varname);
ok( ($length == 15), "default < minimum is automatically corrected");

$varname = make_varname( { default => 20, max => 15 } );
$length = length($varname);
ok( ($length == 15), "default > maximum is automatically corrected");

eval { $varname = make_varname( { min => 12, max => 9, default => 11 } ); };
$pattern = qq{Minimum must be <= Maximum};
like($@, qr/$pattern/, "minimum > maximum correctly fails");

##### SUBROUTINES #####

sub two_basic_tests_default {
    my $def = shift;
    my $varname = make_varname( { default => $def } );
    my $length = length($varname);
    ok( ($length == $def), "length equals default $def");
    
    _first_and_subsequent($varname);
}

