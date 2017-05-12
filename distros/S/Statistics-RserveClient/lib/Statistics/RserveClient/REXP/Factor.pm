# * Rserve client for Perl
# * @author Djun Kim
# * Based on Clément Turbelin's PHP client
# * Licensed under GPL v2 or at your option v3

# * Supports Rserve protocol 0103 only (used by Rserve 0.5 and higher)
# *
# * Developed using code from Simple Rserve client for PHP by Simon
# * Urbanek Licensed under GPL v2 or at your option v3

# * This code is inspired from Java client for Rserve (Rserve package
# * v0.6.2) developed by Simon Urbanek(c)

#use warnings;
#use autodie;

# R Double Factor
# class Rserve_REXP_Factor extends Rserve_REXP_Integer {
package Statistics::RserveClient::REXP::Factor;

our $VERSION = '0.12'; #VERSION

our @ISA = qw (Statistics::RserveClient::REXP::Integer);

use Statistics::RserveClient;
use Statistics::RserveClient qw (:xt_types );

use Statistics::RserveClient::REXP::Integer;

#protected $levels;
my @_levels;

sub isFactor() { return TRUE; }

sub getLevels() {
    return @_levels;
}

sub setLevels($) {
    my @levels = shift;
    @_levels = @levels;
}

sub asCharacters() {
    my @r = array();
    foreach (@_levels) {
        push( @r, $_levels[$_] );
    }
    return @r;
}

sub getType() {
    return Statistics::RserveClient::XT_FACTOR;
}

1;
