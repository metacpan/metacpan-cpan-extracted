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

# * R List

# class Rserve_REXP_List extends Rserve_REXP_Vector implements ArrayAccess {

use Statistics::RserveClient;
use Statistics::RserveClient qw( :xt_types );
use Statistics::RserveClient::REXP::Vector;

package Statistics::RserveClient::REXP::List;

our $VERSION = '0.12'; #VERSION

our @ISA = qw(Statistics::RserveClient::REXP::Vector);

my $names    = ();               # protected
my $is_named = FALSE;    # protected

#sub setValues($values, $getNames = FALSE) {
sub setValues(@) {
    my $self     = shift;
    my $values   = shift;
    my $getNames = shift;
    if ( !defined($getNames) ) {
        $getNames = FALSE;
    }

    my $names = undef;
    if ($getNames) {
        $names = array_keys($values);
    }
    $values = array_values($values);
    parent::setValues($values);
    if ($names) {
        $self->setNames($names);
    }
}

#  * Set names
#  * @param unknown_type $names

sub setNames($$) {
    my $self  = shift;
    my $names = shift;
    if ( count( $self->values ) != count($names) ) {
        #throw new LengthException('Invalid names length');
        die(      "Invalid names length: "
                . count( $self->values ) . " != "
                . count($names) );
    }
    $self::names    = $names;
    $self::is_named = TRUE;
}

# * return array list of names
sub getNames($) {
    my $self = shift;
    return ( $self->is_named ) ? $self->names : array();
}

# * return TRUE if the list is named

sub isNamed() {
    my $self = shift;
    return $self->is_named;
}

# * Get the value for a given name entry, if list is not named, get the indexed element
# * @param string $name

sub at($) {
    my $self = shift;
    my $name = shift;

    if ( $self->is_named ) {
        my $i = array_search( $name, $self->names );
        if ( $i < 0 ) {
            return undef;
        }
        return $self::values[$i];
    }
}

# * Return element at the index $i
# * @param int $i
# * @return mixed Statistics::RserveClient::REXP or native value

sub atIndex($) {
    my $self = shift;
    my $i    = shift;
    $i = 0 + $i;
    my $n = count($self::values);
    if ( ( $i < 0 ) || ( $i >= $n ) ) {
        #throw new OutOfBoundsException('Invalid index');
        die("Index out of bounds: i = $i\n");
    }
    return $self::values[$i];
}

sub isList() { return TRUE; }

sub offsetExists($) {
    my $self   = shift;
    my $offset = shift;
    if ( $self->is_named ) {
        return array_search( $offset, $self->names ) >= 0;
    }
    else {
        return isset( $self::names[$offset] );
    }
}

sub offsetGet($) {
    my $self   = shift;
    my $offset = shift;
    return $self->at($offset);
}

sub offsetSet($$) {
    my $self   = shift;
    my $offset = shift;
    my $value  = shift;
    # throw new Exception('assign not implemented');
    die("Assign not implemented.\n");
}

sub offsetUnset($) {
    my $self   = shift;
    my $offset = shift;
    #throw new Exception('unset not implemented');
    die("Unset not implemented.\n");
}

sub getType() {
    my $self = shift;
    if ( $self->isNamed() ) {
        return Statistics::RserveClient::XT_LIST_TAG;
    }
    else {
        return Statistics::RserveClient::XT_LIST_NOTAG;
    }
}

sub toHTML() {
    my $self = shift;
    $is_named = $self->is_named;
    my $s = '<div class="rexp xt_' . $self->getType() . '">';
    my $n = $self->length();
    $s .= '<ul class="list"><span class="typename">List of ' . $n . '</span>';
    for ( my $i = 0; $i < $n; ++$i ) {
        $s .= '<li>';
        my $idx = ($is_named) ? $self::names[$i] : $i;
        $s .= '<div class="name">' . $idx . '</div>:<div class="value">';
        my $v = $self::values[$i];
        if ( is_object($v) and ( $v->isa('Statistics::RserveClient::REXP') ) ) {
            $s .= $v->toHTML();
        }
        else {
            $s .= '' . $v;
        }
        $s .= '</div>';
        $s .= '</li>';
    }
    $s .= '</ul>';
    $s .= $self->attrToHTML();
    $s .= '</div>';
    return $s;
}

1;

