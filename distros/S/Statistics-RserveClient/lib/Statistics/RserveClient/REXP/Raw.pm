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

#  R Raw data
# class Rserve_REXP_Raw extends Rserve_REXP {

use Statistics::RserveClient;
use Statistics::RserveClient qw (:xt_types );

use Statistics::RserveClient::REXP;

package Statistics::RserveClient::REXP::Raw;

our $VERSION = '0.12'; #VERSION

our @ISA = qw(Statistics::RserveClient::REXP);

my $_value;    #protected

# * return int
sub length($) {
    my $self = shift;
    return strlen( $self->_value );
}

sub setValue($$) {
    my $self  = shift;
    my $value = shift;

    $self->_value = $value;
}

sub getValue($) {
    my $self = shift;
    return $self->_value;
}

sub isRaw() { return TRUE; }

sub getType() {
    return Statistics::RserveClient::XT_RAW;
}

sub toHTML($) {
    my $self = shift;
    my $s
        = strlen( $self->value ) > 60
        ? substr( $self->value, 0, 60 ) . ' (truncated)'
        : $self->value;
    return
          '<div class="rexp xt_'
        . $self->getType()
        . '"> <span class="typename">raw</span><div class="value">'
        . $s
        . '</div>'
        . $self->attrToHTML()
        . '</div>';
}

1;
