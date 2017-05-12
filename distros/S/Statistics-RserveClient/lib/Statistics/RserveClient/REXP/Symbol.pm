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

# R symbol element
# class Rserve_REXP_Symbol extends Rserve_REXP {

use Statistics::RserveClient;
use Statistics::RserveClient qw (:xt_types );

use Statistics::RserveClient::REXP;
use Statistics::RserveClient::Parser;

package Statistics::RserveClient::REXP::Symbol;

our $VERSION = '0.12'; #VERSION

our @ISA = qw(Statistics::RserveClient::REXP);

sub new($$) {
    my $class = shift;
    my $self = {
        name => shift,
    };
    bless $self, $class;
    return $self;
}

sub setValue($$) {
    my $self = shift;
    my $name = shift;
    $self->{name} = $name;
}

sub getValue($) {
    my $self = shift;
    return $self->{name};
}

sub isSymbol() { return TRUE; }

sub getType() {
    return Statistics::RserveClient::XT_SYM;
}

sub toHTML($) {
    my $self = shift;

    my $type = $self->getType() . "";

    return
          '<div class="rexp xt_' . $type . '">' . "\n"
        . '<span class="typename">'
        . Statistics::RserveClient::Parser::xtName( $type )
        . '</span>' . "\n"
        . $self->{name}
        . $self->attrToHTML() . "\n"
        . '</div>';
}

sub __toString($) {
    my $self = shift;

    return '"' . $self->{name} . '"';
}

1;
