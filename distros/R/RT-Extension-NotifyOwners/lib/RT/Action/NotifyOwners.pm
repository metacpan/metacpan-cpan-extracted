use strict;
use warnings;

package RT::Action::NotifyOwners;

use base qw(RT::Extension::NotifyOwners);

sub SetRecipients {
    my $self = shift;

    # Recipient list
    my ( @To );

    # Populate the recipient list based on argument
    my $arg = $self->Argument;

    if ( $arg =~ /\bLastOwner\b/ ) {
        @To = $self->LastOwner();
    }

    if ( $arg =~ /\bPotentialOwners\b/ ) {
        @To = $self->PotentialOwners();
    }

    if ( $arg =~ /\bPrevOwners\b/ ) {
        @To = $self->PrevOwners();
    }

    # Creator of this transaction so we can check NotifyActor
    my $creator = $self->TransactionObj->CreatorObj->EmailAddress();

    # Only notify the creator of the transaction if NotifyActor is set
    if (RT->Config->Get('NotifyActor')) {
        @{ $self->{'To'} }  = @To;
    } else {
        @{ $self->{'To'} }  = grep ( lc $_ ne lc $creator, @To );
    }

    # Remove the 'Nobody' user from the To field
    grep ( lc $_ ne lc $RT::Nobody->EmailAddress, @To);

    $RT::Logger->debug("SetRecipients is setting To field to '" . join( ",", @To ) . "'");

    return 1;
}

1;
