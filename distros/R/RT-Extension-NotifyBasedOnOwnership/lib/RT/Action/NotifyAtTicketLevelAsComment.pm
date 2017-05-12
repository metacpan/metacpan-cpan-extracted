use strict;
use warnings;

package RT::Action::NotifyAtTicketLevelAsComment;
use base qw(RT::Action::NotifyAtTicketLevel);

sub SetReturnAddress {
    my $self = shift;
    $self->{'comment'} = 1;
    return $self->SUPER::SetReturnAddress( @_, is_comment => 1 );
}

=head1 NAME

RT::Action::NotifyAtTicketLevelAsComment

=head1 DESCRIPTION

A subclass of L<RT::Action::NotifyAtTicketLevel> which sends notifications
flagged as a comment instead of a correspondence (reply).  This is appropriate
for redistributing comments.

Takes the same arguments as L<RT::Action::NotifyAtTicketLevel>.

=cut

1;
