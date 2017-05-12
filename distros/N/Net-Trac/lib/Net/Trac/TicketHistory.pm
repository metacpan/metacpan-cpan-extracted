use strict;
use warnings;

package Net::Trac::TicketHistory;

use Any::Moose;
use Params::Validate qw(:all);
use Net::Trac::TicketHistoryEntry;

=head1 NAME

Net::Trac::TicketHistory - A Trac ticket's history

=head1 SYNOPSIS

    my $history = Net::Trac::TicketHistory->new( connection => $trac );
    $history->load( 13 );

    # Print the authors of all the changes to ticket #13
    for ( @{ $history->entries } ) {
        print $_->author, "\n";
    }

=head1 DESCRIPTION

This class represents a Trac ticket's history and is really just a collection
of L<Net::Trac::TicketHistoryEntries>.

=head1 ACCESSORS

=head2 connection

=head2 ticket

Returns the ID of the ticket whose history this object represents.

=head2 entries

Returns an arrayref of L<Net::Trac::TicketHistoryEntry>s.

=cut

has connection => (
    isa => 'Net::Trac::Connection',
    is  => 'ro'
);

has ticket  => ( isa => 'Net::Trac::Ticket',      is => 'rw', weak_ref => 1);
has entries => ( isa => 'ArrayRef', is => 'rw' );

=head1 METHODS

=head2 load ID

Loads the history of the specified ticket.

=cut

sub load {
    my $self = shift;
    my ($ticket_obj) = validate_pos( @_, 1);

    $self->ticket( $ticket_obj );

    # Clone the ticket state so we can morph it backwards to reverse engineer
    # keywords
    my $temp_state = { %{ $ticket_obj->state()}};

    my $feed_content = $self->connection->_fetch( "/ticket/@{[$ticket_obj->id]}?format=rss" )
        or return;

    my $entries = '';
    if ($feed_content =~ m|^(?:.*?)<item>(.*)</item>(?:.*?)$|is) {
        $entries = $1;
    }

    my @entries = split(m|</item>\s*<item>|, $entries);

    my @history;
    # Work on the newest entry first so we can back-calculate from the current state
    foreach my $entry (reverse @entries) {
        my $e = Net::Trac::TicketHistoryEntry->new({ connection => $self->connection, ticket => $self->ticket });
        $e->parse_feed_entry($entry, $temp_state);
        # newest entry should be at the front of the list in the history later
        unshift @history, $e;
    }


    # trac doesn't have a history entry for ticket creation. Let's fake one up
    my $creation =Net::Trac::TicketHistoryEntry->new({connection => $self->connection});
    #  Reporter can change. really, we should work backwards through the whole history
    #  to get the first version
    $creation->ticket($self->ticket);
    $creation->is_create(1);
    $creation->author($self->ticket->reporter);
    $creation->date($self->ticket->created);
    $creation->content('Ticket created');
    $creation->category('Ticket');
    unshift @history, $creation;

    $self->entries( \@history );
    return 1;
}

=head1 LICENSE

Copyright 2008-2009 Best Practical Solutions.

This package is licensed under the same terms as Perl 5.8.8.

=cut

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
