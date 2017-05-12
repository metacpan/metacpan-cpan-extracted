no warnings 'redefine';

@ACTIVE_STATUS = qw(new open stalled reopened);
@INACTIVE_STATUS = qw(resolved rejected deleted);
@STATUS = (@ACTIVE_STATUS, @INACTIVE_STATUS);

sub SetOrigin {
    my $self = shift;
    $self->SetDefaultDueIn(@_);
}

sub Origin {
    my $self = shift;
    $self->DefaultDueIn;
}

sub OriginObj {
    my $self = shift;
    my $Id = $self->DefaultDueIn or return;
    my $Ticket = RT::Ticket->new($RT::SystemUser);
    $Ticket->Load($Id);
    return unless $Ticket->Id;
    $Ticket;
}

sub CustomFields {
    my $self = shift;

    my $cfs = RT::CustomFields->new( $self->CurrentUser );
    if ( $self->CurrentUserHasRight('SeeQueue') ) {
	if ($self->Disabled and $self->Description eq 'RT Foundry System') {
	    $cfs->LimitToQueue( $self->Id );
	}
	else {
	    $cfs->LimitToGlobalOrQueue( $self->Id );
	}
    }
    return ($cfs);
}


1;
