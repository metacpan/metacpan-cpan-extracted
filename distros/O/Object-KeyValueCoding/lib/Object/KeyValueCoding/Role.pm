package Object::KeyValueCoding::Role;

use strict;
use warnings;

use Moose::Role;

# This will glom the methods into this class
# and should be sufficient for what you need.
use Object::KeyValueCoding::Complex;

my $__KEY_VALUE_CODING = Object::KeyValueCoding::Complex->implementation( additions => 1 );

sub valueForKey {
    my ( $self, $key ) = @_;
    return $__KEY_VALUE_CODING->{__valueForKey}->( $self, $key );
}

sub setValueForKey {
    my ( $self, $value, $key ) = @_;
    return $__KEY_VALUE_CODING->{__setValueForKey}->( $self, $value, $key );
}

sub valueForKeyPath {
    my ( $self, $keyPath ) = @_;
    return $__KEY_VALUE_CODING->{__valueForKeyPath}->( $self, $keyPath );
}

sub setValueForKeyPath {
    my ( $self, $value, $keyPath ) = @_;
    return $__KEY_VALUE_CODING->{__setValueForKeyPath}->( $self, $value, $keyPath );
}

sub accessorKeyList {
    my ( $self, $key ) = @_;
    return $__KEY_VALUE_CODING->{__accessorKeyList}->( $key );
}

sub setterKeyList {
    my ( $self, $key ) = @_;
    return $__KEY_VALUE_CODING->{__setterKeyList}->( $key );
}

sub stringWithEvaluatedKeyPathsInLanguage {
    my ( $self, $string, $language ) = @_;
    return $__KEY_VALUE_CODING->{__stringWithEvaluatedKeyPathsInLanguage}->( $string, $language );
}

1;