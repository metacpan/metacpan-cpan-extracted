# t/02_specified.t - tests for specified length
use Test::More tests => 55;
use strict;
use warnings;

BEGIN { use_ok( 'String::PerlIdentifier' ); }
use lib ("t/");
use Auxiliary qw{ _first_and_subsequent };

our (%eligibles, %chars);
require "t/eligible_chars";

specified_length_tests($_) for (3..20);

sub specified_length_tests {
    my $specified = shift;
    my $varname = make_varname($specified);
    my $length = length($varname);
    is( $length, $specified, "length of string is $specified as specified");
    
    _first_and_subsequent($varname);
}

