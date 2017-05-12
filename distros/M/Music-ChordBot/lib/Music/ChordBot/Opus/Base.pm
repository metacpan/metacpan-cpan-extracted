#! perl

use strict;
use warnings;
use utf8;

package Music::ChordBot::Opus::Base;

=head1 NAME

Music::ChordBot::Opus::Base - Base class for ChordBot classes.

=cut

our $VERSION = 0.01;

# Accessor for data.

sub data { $_[0]->{data} }

# Generic set/get routine. Without a value, it returns the current
# value. With a value it sets the attribute and returns $self so it
# can be chained.

sub _setget {
    my ( $self, $key, $value ) = @_;
    return $self->{data}->{$key} unless defined $value;
    $self->{data}->{$key} = $value;
    return $self;
}

1;
