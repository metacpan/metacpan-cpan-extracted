package Auxiliary;
use strict;
use warnings;
our ($VERSION, @ISA, @EXPORT_OK);
$VERSION = '0.05_01';
require Exporter;
@ISA         = qw(Exporter);
@EXPORT_OK   = qw(
    _first_and_subsequent
); 
*ok = *Test::More::ok;
use lib ('.'); # where '.' => 't/'

our (%eligibles, %chars);
require "t/eligible_chars";

sub _first_and_subsequent {
    my $varname = shift;
    my @els = split(q{}, $varname);
    ok( $eligibles{$els[0]},
        "first character in variable is letter or underscore");
    my @balance = @els[1..$#els];
    my $factor = 0;
    while ( defined ( my $k = shift @balance ) ) {
        $factor = 1 if ! $chars{$k};
        last if $factor;
    }
    ok(! $factor, "characters 2..last are letters, numerals or underscore");
}

1;
