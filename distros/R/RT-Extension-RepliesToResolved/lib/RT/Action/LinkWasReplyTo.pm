package RT::Action::LinkWasReplyTo;
use base 'RT::Action';
use strict;

sub Describe {
    my $self = shift;
    return ( ref $self );
}

sub Prepare {
    return 1;
}

sub Commit {
    my $self            = shift;

    my $r2r_config = RT->Config->Get('RepliesToResolved');

    my $Ticket = $self->TicketObj;
    my $queue = $Ticket->QueueObj->Name;

    my $linktype = $r2r_config->{'default'}->{'link-type'};
    if (exists($r2r_config->{$queue})) {
        if (exists($r2r_config->{$queue}->{'link-type'})) {
            $linktype = $r2r_config->{$queue}->{'link-type'};
        }
    }

    return 1 unless (defined($linktype));

    my $Transaction     = $self->TransactionObj;
    my $FirstAttachment = $Transaction->Attachments->First;
    return 1 unless $FirstAttachment;

    my $OldTicket = $FirstAttachment->GetHeader('X-RT-Was-Reply-To');
    return 1 unless $OldTicket;

    my ($val, $msg);
    my $map = $Ticket->can('LINKTYPEMAP') ? $Ticket->LINKTYPEMAP :  # 4.0
                                            { %RT::Link::TYPEMAP }; # 4.2

    ($val, $msg) = $Ticket->AddLink(Type => $map->{$linktype}->{'Type'},
                                    $map->{$linktype}->{'Mode'} => $OldTicket);

    if ($val == 0) {
        RT->Logger->error('Failed to link '.$Ticket->id.'to '.$OldTicket.": $msg\n");
    }    

    return ($val);
}

RT::Base->_ImportOverlays();

1;
