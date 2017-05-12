use strict;
use warnings;

package RT::Condition::Owner;
use base qw(RT::Condition);

sub IsApplicable {
    my $self  = shift;
    my $owner = $self->TicketObj->Owner;
    my $arg   = $self->Argument || '';

    if ($arg eq '*') {
        return $owner && $owner != RT->Nobody->Id;
    }
    elsif (lc $arg eq 'Nobody') {
        return $owner == RT->Nobody->Id;
    }
    elsif ($arg) {
        my $user = RT::User->new( $self->CurrentUser );
        $user->Load($arg);
        return $user->Id && $owner == $user->Id;
    }

    return 0;
}

=head1 NAME

RT::Condition::Owner

=head1 DESCRIPTION

This is an RT scrip condition which tests a ticket for the state of ownership,
depending on the C<Argument> provided by the L<RT::ScripCondition>.  The
following arguments are recognized:

=over

=item C<*>

Condition succeeds if the ticket is assigned to a real person, that is, not
Nobody.

=item C<Nobody>

Condition succeeds if the ticket is assigned to Nobody, that is, if the ticket
is unowned by a real person.

=item I<a username>

Condition succeeds if the ticket is assigned to the user specified.  The
Argument value must be a user name.

=back

=cut

1;

