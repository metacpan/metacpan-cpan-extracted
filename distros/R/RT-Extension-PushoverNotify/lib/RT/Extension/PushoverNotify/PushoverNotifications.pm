#!/usr/bin/perl

use strict;
use warnings;
use 5.10.1;

package RT::Extension::PushoverNotify::PushoverNotifications;

use base 'RT::SearchBuilder';

use RT::Extension::PushoverNotify::PushoverNotification;

=head1 NAME

  RT::Extension::PushoverNotify::PushoverNotifications - Search class for PushoverNotification

See perldoc DBIx::SearchBuilder

=cut

sub _Init {
    my $self = shift;
    $self->Table( RT::Extension::PushoverNotify::PushoverNotification->Table() );
    return $self->SUPER::_Init(@_);
}

sub NewItem {
    my $self = shift;
    return RT::Extension::PushoverNotify::PushoverNotification->new( $self->CurrentUser ); 
}

1;
