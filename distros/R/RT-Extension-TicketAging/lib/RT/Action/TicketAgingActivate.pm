package RT::Action::TicketAgingActivate;

use strict;
use warnings;

use base qw(RT::Action::Generic);

sub Prepare { return 1 }

sub Commit {
    my $self = shift;

    my $ticket = $self->TicketObj;
    $self->Activate( $ticket );

    my $id = $ticket->id;
    foreach my $type ( qw(MemberOf DependsOn HasMember DependedOnBy) ) {
        my $query = "CF.{Age} != 'Active' AND $type = $id";
        my $tickets = RT::Tickets->new( $RT::SystemUser );
        $tickets->FromSQL( $query );
        while ( my $t = $tickets->Next ) {
            $self->Activate( $t );
        }
    }
    return 1;
}

sub Activate {
    my $self = shift;
    my $ticket = shift;
    my ($status, $msg) = $ticket->AddCustomFieldValue(
        Field => 'Age',
        Value => 'Active',
        RecordTransaction => 0,
    );
    $RT::Logger->warning("Couldn't set age to active: $msg")
        unless $status;
}

1;

