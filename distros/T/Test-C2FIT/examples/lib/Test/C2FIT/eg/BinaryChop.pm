# Copyright (c) 2003 Cunningham & Cunningham, Inc.
# Read license.txt in this directory.
#
# Perl translation by Martin Busik <martin.busik@busik.de>
#

package Test::C2FIT::eg::BinaryChop;
use base 'Test::C2FIT::ColumnFixture';
use strict;

sub new {
    my $pkg = shift;
    return $pkg->SUPER::new(
        fieldColumnTypeMap => { 'array' => 'Test::C2FIT::GenericArrayAdapter' }
    );
}

sub execute {
    my $self = shift;
    $self->{array} = [] unless ref( $self->{array} );
}

sub _ka(@) {
    my $self = shift;
    return ( $self->{key}, $self->{array} );
}

sub result {
    chopFriday( _ka(@_) );
}

sub mon { chopMonday( _ka(@_) ) }
sub tue { result(@_) }
sub wed { result(@_) }
sub thr { result(@_) }
sub fri { result(@_) }

sub chopMonday($$) {
    my ( $key, $array ) = @_;
    my $min = 0;
    my $max = @$array - 1;
    while ( $min <= $max ) {
        my $probe = int( ( $min + $max ) / 2 );
        return $probe if $key == $array->[$probe];
        if ( $key > $array->[$probe] ) {
            $min = $probe + 1;
        }
        else {
            $max = $probe - 1;
        }
    }
    return -1;
}

sub chopFriday($$) {
    my ( $key, $array ) = @_;

    for ( my $i = 0 ; $i < scalar(@$array) ; $i++ ) {
        return $i if $array->[$i] == $key;
    }
    return -1;
}

1;
