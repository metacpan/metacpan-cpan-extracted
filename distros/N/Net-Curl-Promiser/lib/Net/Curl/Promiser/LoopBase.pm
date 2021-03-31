package Net::Curl::Promiser::LoopBase;

use strict;
use warnings;

=head1 NAME

Net::Curl::Promiser::LoopBase - Base class for event-loop-based implementations

=head1 DESCRIPTION

This subclass of L<Net::Curl::Promiser> provides abstract behaviors for
event loops. It doesn’t change the interface.

=cut

#----------------------------------------------------------------------

use parent qw( Net::Curl::Promiser );

use Net::Curl::Multi ();

#----------------------------------------------------------------------

sub new {
    my $self = shift()->SUPER::new(@_);

    my ($backend, $multi) = @{$self}{'backend', 'multi'};

    $multi->setopt(
        Net::Curl::Multi::CURLMOPT_TIMERDATA(),
        $backend,
    );

    $multi->setopt(
        Net::Curl::Multi::CURLMOPT_TIMERFUNCTION(),
        $backend->can('_CB_TIMER'),
    );

    return $self;
}

sub _SETOPT_FORBIDDEN {
    my ($self_or_class) = @_;

    return (
        $self_or_class->SUPER::_SETOPT_FORBIDDEN(),
        qw( TIMERFUNCTION  TIMERDATA ),
    );
}

1;
