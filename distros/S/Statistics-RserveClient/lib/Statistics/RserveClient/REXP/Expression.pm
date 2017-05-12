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

use Statistics::RserveClient;
use Statistics::RserveClient qw (:xt_types );

use Statistics::RserveClient::REXP;
use Statistics::RserveClient::REXP::GenericVector;

#class Rserve_REXP_Factor extends Rserve_REXP_GenericVector {
package Statistics::RserveClient::REXP::Expression;

our $VERSION = '0.12'; #VERSION

our @ISA = qw(Statistics::RserveClient::REXP::GenericVector);

sub isExpression() { return TRUE; }

sub getType() {
    return Statistics::RserveClient::XT_VECTOR_EXP;
}

1;
