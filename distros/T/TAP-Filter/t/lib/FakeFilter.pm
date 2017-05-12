package FakeFilter;

use strict;
use warnings;
use Carp;
use Storable qw( dclone );
use base qw( TAP::Filter::Iterator );

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );
    $self->{_seen} = [];
    return $self;
}

sub _record { push @{ shift->{_seen} }, [ ( caller 1 )[3], @_ ] }
sub get_log { splice @{ shift->{_seen} } }

sub inspect {
    my $self = shift;
    $self->_record( @_ );
    my $result = shift;
    return dclone $result;
}

sub init {
    my $self = shift;
    $self->_record( @_ );
}

sub done {
    my $self = shift;
    $self->_record( @_ );
}

1;
