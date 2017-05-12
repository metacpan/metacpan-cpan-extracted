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
use Statistics::RserveClient::Parser;

use Exporter;

# R Double vector
# class Rserve_REXP_Vector extends Rserve_REXP {
package Statistics::RserveClient::REXP::Vector;

our $VERSION = '0.12'; #VERSION

our @ISA = qw(Statistics::RserveClient::REXP Exporter);

sub new() {
    my $class = shift;
    my $self = { _values => undef, };
    bless $self, $class;
    return $self;
}

# Returns TRUE (1)
sub isVector() {
    return TRUE;
}

# Returns the length of the instance vector
sub length() {
    my $self = shift;
    return defined( $self->{_values} ) ? ( @{ $self->{_values} } ) : 0;
}

# Sets the value of the instance vector to the value of the given array reference
sub setValues($$) {
    my $self      = shift;
    my $valuesref = shift;
    my @values    = @$valuesref;
    my $sv        = \@{ $self->{_values} };
    @$sv = @values;
    return @{ $self->{_values} };
}

# Gets the value of the instance vector
sub getValues($) {
    my $self = shift;
    return defined( $self->{_values} ) ? @{ $self->{_values} } : ();
}

# * Get value
# * @param unknown_type $index
sub at($) {
    my $self  = shift;
    my $index = shift;
    return @{ $self->{_values} }[$index];
}

# * Gets the type of this object
sub getType() {
    return Statistics::RserveClient::XT_VECTOR;
}

sub toHTML($) {
    my $self = shift;
    my $s    = "<div class='rexp vector xt_" . $self->getType() . "'>\n";
    my $n    = $self->length();
    $s
        .= '<span class="typename">'
        . Statistics::RserveClient::Parser::xtName( $self->getType() )
        . "</span>\n"
        . "<span class='length'>$n</span>\n";
    $s .= "<div class='values'>\n";
    if ($n) {
        my $m = ( $n > 20 ) ? 20 : $n;
        for ( my $i = 0; $i < $m; ++$i ) {
            my $v = @{ $self->{_values} }[$i];
            if ( ref($v) and ( $v->isa('Statistics::RserveClient::REXP') ) ) {
                $v = $v->toHTML();
            }
            else {
                if ( $self->isString() ) {
                    $v = '"' . $v . '"';
                }
                else {
                    $v = "" . $v;
                }
            }
            # print "^$v\n";
            $s .= "<div class='value'>$v</div>\n";
        }
    }
    $s .= "</div>\n";
    $s .= $self->attrToHTML();
    $s .= '</div>';
    return $s;
}

1;
