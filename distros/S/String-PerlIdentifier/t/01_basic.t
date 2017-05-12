# t/01_basic.t - four basic tests
use Test::More tests => 41;
use strict;
use warnings;

BEGIN { use_ok( 'String::PerlIdentifier' ); }
use lib ("t/");
use Auxiliary qw{ _first_and_subsequent };

four_basic_tests() for (1..10);

sub four_basic_tests {
    my $varname = make_varname();
    my $length = length($varname);
    ok( ($length >= 3), "length meets or exceeds minimum");
    ok( ($length <= 20), "length meets or is less than maximum");
    
    _first_and_subsequent($varname);
}

