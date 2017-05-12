package Net::IMAP::Server::Mailbox;

use warnings;
use strict;

use Net::IMAP::Server::Message;
use base 'Class::Accessor';

__PACKAGE__->mk_accessors(
    qw(is_inbox parent children _path uidnext uids uidvalidity messages subscribed is_selectable)
);

=head1 NAME

Net::IMAP::Server::Mailbox - A user's view of a mailbox

=head1 DESCRIPTION

This class encapsulates the view of messages in a mailbox.  You may
wish to subclass this class in order to source our messages from, say,
a database.

=head1 METHODS

=head2 Initialization

=head3 new

Creates a new mailbox; returns C<undef> if a mailbox with the same
full path already exists.  It calls L</init>, then L</load_data>.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    return
        if $self->parent
        and grep { $self->full_path eq $_->full_path }
        @{ $self->parent->children };
    $self->is_inbox(1)
        if $self->parent
        and not $self->parent->parent
        and $self->name =~ /^inbox$/i;
    $self->init;
    $self->load_data;
    return $self;
}

=head3 init

Sets up basic properties of the mailbox:

=over

=item *

L</uidnext> is set to 1000

=item *

L</messages> and L</uids> are initialized to an empty list reference
and an empty hash reference, respectively.

=item *

L</children> is set to an empty list reference.

=item *

L</uidvalidity> is set to the number of seconds since the epoch.

=item *

L</subscribed> and L</is_selectable> are set true.

=back

=cut

sub init {
    my $self = shift;
    $self->uidnext(1000);
    $self->messages( [] );
    $self->uids( {} );
    $self->children( [] );
    $self->uidvalidity(time);
    $self->subscribed(1);
    $self->is_selectable(1);
}

=head3 load_data

This default mailbox implementation simply returns an empty mailbox.
Subclasses will probably wish to override this method.

=cut

sub load_data {
}

=head3 name

Gets or sets the name of the mailbox.  This includes a workaround for
Zimbra, which doesn't understand mailbox names with colons in them --
so we substitute dashes.

=cut

sub name {
    my $self = shift;
    if (@_) {
        $self->{name} = shift;
    }

    # Zimbra can't handle mailbox names with colons in them, for no
    # obvious reason.  Handily, it identifies itself as Zimbra before
    # login, so we know when to perform a colonoscopy.  We do this on
    # get, and not on set, because the same model might be used by
    # other clients.
    my $name = $self->{name};
    $name =~ s/:+/-/g
        if Net::IMAP::Server->connection
        and exists Net::IMAP::Server->connection->client_id->{vendor}
        and Net::IMAP::Server->connection->client_id->{vendor} eq "Zimbra";

    return $name;
}

=head2 Actions

=head3 poll

Called when the server wishes the mailbox to update its state.  By
default, does nothing.  Subclasses will probably wish to override this
method.

=cut

sub poll { }

=head3 add_message MESSAGE

Adds the given L<Net::IMAP::Server::Message> C<MESSAGE> to the mailbox,
setting its L<Net::IMAP::Server::Message/sequence> and
L<Net::IMAP::Server::Message/mailbox>.
L<Net::IMAP::Server::Message/uid> is set to L</uidnext> if the message
does not already have a C<uid>.

=cut

sub add_message {
    my $self    = shift;
    my $message = shift;

    # Basic message setup first
    $message->mailbox($self);
    $message->sequence( @{ $self->messages } + 1 );
    push @{ $self->messages }, $message;

    # Some messages may supply their own uids
    if ( $message->uid ) {
        $self->uidnext( $message->uid + 1 )
            if $message->uid >= $self->uidnext;
    } else {
        $message->uid( $self->uidnext );
        $self->uidnext( $self->uidnext + 1 );
    }
    $self->uids->{ $message->uid } = $message;

    # Also need to add it to anyone that has this folder as a
    # temporary message store
    for my $c ( Net::IMAP::Server->concurrent_mailbox_connections($self) ) {
        next unless $c->temporary_messages;

        push @{ $c->temporary_messages }, $message;
        $c->temporary_sequence_map->{$message}
            = scalar @{ $c->temporary_messages };
    }
    return $message;
}

=head3 add_child [...]

Creates a mailbox under this mailbox, of the same class as this
mailbox is.  Any arguments are passed to L</new>.  Returns the newly
added subfolder, or undef if a folder with that name already exists.

=cut

sub add_child {
    my $self = shift;
    my $node = ( ref $self )->new( { @_, parent => $self } );
    return unless $node;
    push @{ $self->children }, $node;
    return $node;
}

=head3 create [...]

Identical to L</add_child>.  Should return false if the create is
denied or fails.

=cut

sub create {
    my $self = shift;
    return $self->add_child(@_);
}

=head3 reparent MAILBOX [NAME]

Reparents this mailbox to be a child of the given
L<Net::IMAP::Server::Mailbox> C<MAILBOX>, with the given C<NAME>.
Should return 0 if the reparenting is denied or fails.

=cut

sub reparent {
    my $self   = shift;
    my $parent = shift;

    $self->parent->children(
        [ grep { $_ ne $self } @{ $self->parent->children } ] );
    push @{ $parent->children }, $self;
    $self->parent($parent);
    $self->name(shift) if @_;
    $self->full_path( purge => 1 );
    return 1;
}

=head3 delete

Deletes this mailbox, removing it from its parent's list of children.
Should return false if the deletion is denied or fails.

=cut

sub delete {
    my $self = shift;
    $self->parent->children(
        [ grep { $_ ne $self } @{ $self->parent->children } ] );

    return 1;
}

=head3 expunge [ARRAYREF]

Expunges messages marked as C<\Deleted>.  If an arrayref of message
sequence numbers is provided, only expunges message from that set.

=cut

sub expunge {
    my $self = shift;
    my $only = shift;
    return if $only and not @{$only};
    my %only;
    $only{$_}++ for @{ $only || [] };

    my @ids;
    my $offset   = 0;
    my @messages = @{ $self->messages };
    $self->messages(
        [   grep {
                not( $_->has_flag('\Deleted')
                    and ( not $only or $only{ $_->sequence } ) )
                } @messages
        ]
    );
    for my $c ( Net::IMAP::Server->concurrent_mailbox_connections($self) ) {

        # Ensure that all other connections with this selected get a
        # temporary message list, if they don't already have one
        unless (
                # Except if we find our own connection; if this is
                # *not* part of a poll, we asked for it, so no need to
                # set up temporary messages.
            ( Net::IMAP::Server->connection and
              $c eq Net::IMAP::Server->connection
              and not $c->in_poll
            )
            or $c->temporary_messages
            )
        {
            $c->temporary_messages( [@messages] );
            $c->temporary_sequence_map( {} );
            $c->temporary_sequence_map->{$_} = $_->sequence for @messages;
        }
    }

    for my $m (@messages) {
        if ( $m->has_flag('\Deleted')
            and ( not $only or $only{ $m->sequence } ) )
        {
            push @ids, $m->sequence - $offset;
            delete $self->uids->{ $m->uid };
            $offset++;
            $m->expunge;
        } elsif ($offset) {
            $m->sequence( $m->sequence - $offset );
        }
    }

    for my $c ( Net::IMAP::Server->concurrent_mailbox_connections($self) ) {

        # Also, each connection gets these added to their expunge list
        push @{ $c->_unsent_expunge }, @ids;
    }

    return 1;
}

=head3 append MESSAGE

Appends, and returns, the given C<MESSAGE>, which should be a string
containing the message.  Returns false is the append is denied or
fails.

=cut

sub append {
    my $self = shift;
    my $m    = Net::IMAP::Server::Message->new(@_);
    $m->set_flag( '\Recent', 1 );
    $self->add_message($m);
    return $m;
}

=head3 close

Called when the client selects a different mailbox, or when the
client's connection closes.  By default, does nothing.

=cut

sub close { }

=head2 Inspection

=head3 separator

Returns the path separator.  Note that only the path separator of the
root mailbox matters.  Defaults to a forward slash.

If the function returns is undef, the server supports only flat
mailboxes (i.e. no child mailboxes are allowed).

=cut

sub separator {
    return "/";
}

=head3 full_path [purge => 1]

Returns the full path to this mailbox.  This value is cached
aggressively on a per-connection basis; passing C<purge> flushes this
cache, if the path name has changed.

=cut

sub full_path {
    my $self = shift;
    my %args = @_;
    my $cache
        = Net::IMAP::Server->connection
        ? ( Net::IMAP::Server->connection->{path_cache} ||= {} )
        : {};

    if ($args{purge}) {
        my @uncache = ($self);
        while (@uncache) {
            my $o = shift @uncache;
            delete $cache->{$o.""};
            push @uncache, @{ $o->children };
        }
    }

    return $cache->{$self.""}
      if defined $cache->{$self.""};
    $cache->{$self.""} =
          !$self->parent         ? ""
        : !$self->parent->parent ? $self->name
        : $self->parent->full_path . $self->separator . $self->name;
    return $cache->{$self.""};
}

=head3 flags

Returns the list of flags that this mailbox supports.

=cut

sub flags {
    my $self = shift;
    return qw(\Answered \Flagged \Deleted \Seen \Draft);
}

=head3 can_set_flag FLAG

Returns true if the client is allowed to set the given flag in this
mailbox; this simply scans L</flags> to check.

=cut

sub can_set_flag {
    my $self = shift;
    my $flag = shift;

    return 1 if grep { lc $_ eq lc $flag } $self->flags;
    return;
}

=head3 exists

Returns the number of messages in this mailbox.  Observing this also
sets the "high water mark" for notifying the client of messages added.

=cut

sub exists {
    my $self = shift;
    Net::IMAP::Server->connection->previous_exists(
        scalar @{ $self->messages } )
        if $self->selected;
    return scalar @{ $self->messages };
}

=head3 recent

Returns the number of messages which have the C<\Recent> flag set.

=cut

sub recent {
    my $self = shift;
    return scalar grep { $_->has_flag('\Recent') } @{ $self->messages };
}

=head3 first_unseen

Returns the sequence number of the first message which does not have
the C<\Seen> flag set.  Returns 0 if all messages have been marked as
C<\Seen>.

=cut

sub first_unseen {
    my $self = shift;
    for ( @{ $self->messages } ) {
        next if $_->has_flag('\Seen');
        return Net::IMAP::Server->connection
            ? Net::IMAP::Server->connection->sequence($_)
            : $_->sequence;
    }
    return 0;
}

=head3 unseen

Returns the number of messages which do not have the C<\Seen> flag set.

=cut

sub unseen {
    my $self = shift;
    return scalar grep { not $_->has_flag('\Seen') } @{ $self->messages };
}

=head3 permanentflags

Returns the flags which will be stored permanently for this mailbox;
defaults to the same set as L</flags> returns.

=cut

sub permanentflags {
    my $self = shift;
    return $self->flags;
}


=head3 status TYPES

Called when the clients requests a status update (via
L<Net::IMAP::Server::Command::Status>).  C<TYPES> should be the types
of information requested, chosen from this list:

=over

=item MESSAGES

The number of messages in the mailbox (via L</exists>)

=item RECENT

The number of messages marked as C<\Recent> (via L</recent>)

=item UNSEEN

The number of messages not marked as C<\Seen> (via L</unseen>)

=item UIDVALIDITY

The C</uidvalidity> of the mailbox.

=item UIDNEXT

The C</uidnext> of the mailbox.

=back

=cut

sub status {
    my $self = shift;
    my (@keys) = @_;
    $self->poll;
    my %items;
    for my $i ( @keys ) {
        if ( $i eq "MESSAGES" ) {
            $items{$i} = $self->exists;
        } elsif ( $i eq "RECENT" ) {
            $items{$i} = $self->recent;
        } elsif ( $i eq "UNSEEN" ) {
            $items{$i} = $self->unseen;
        } elsif ( $i eq "UIDVALIDITY" ) {
            my $uidvalidity = $self->uidvalidity;
            $items{$i} = $uidvalidity if defined $uidvalidity;
        } elsif ( $i eq "UIDNEXT" ) {
            my $uidnext = $self->uidnext;
            $items{$i} = $uidnext if defined $uidnext;
        }
    }
    return %items;
}

=head3 read_only

Returns true if this mailbox is read-only.  By default, the value of
this depends on if the mailbox was selected using C<EXAMINE> or
C<SELECT> (see L<Net::IMAP::Server::Command::Select> and
L<Net::IMAP::Server::Connection/selected_read_only>)

=cut

sub read_only {
    my $self = shift;
    return unless Net::IMAP::Server->connection;
    return $self->selected
        && Net::IMAP::Server->connection->selected_read_only;
}

=head3 select

Called when the mailbox is selected; by default does nothing.  Note
that this could be called a a result of either a SELECT or an EXAMINE.

=cut

sub select {}

=head3 selected

Returns true if this mailbox is the mailbox selected by the current
L<Net::IMAP::Server::Connection>.

=cut

sub selected {
    my $self = shift;
    return 1 if Net::IMAP::Server->connection
      and Net::IMAP::Server->connection->selected
        and Net::IMAP::Server->connection->selected eq $self;
    return;
}

=for private

This method exists to choose the most apppriate strategy to take the
intersection of (uids asked for) n (uids we have), by examining the
cardinality of each set, and iterating over the smaller of the two.
This is particularly important, as many clients try to fetch UIDs 1:*,
which will exhaust memory if the naive approach is taken, and there is
one message with UID 100_000_000.

=cut

sub _uids_in_range {
    my $self = shift;
    my ( $low, $high ) = @_;
    ( $low, $high ) = ( $high, $low ) if $low > $high;

    my $count = scalar @{ $self->messages };
    if ( $high - $low > $count ) {

        # More UIDs to enumerate than we actually have; check each
        # existing UID for being in the range
        return grep {$_ >= $low and $_ <= $high} map $_->uid, @{ $self->messages };
    } else {

        # More messages than in the UID range; enumerate the range and
        # check each against UIDs which exist
        my $uids = $self->uids;
        return grep {defined $uids->{$_}} $low .. $high;
    }
}

=head3 get_uids STR

Parses and returns messages fitting the given UID range.

=cut

sub get_uids {
    my $self = shift;
    my $str  = shift;

    # Otherwise $self->messages->[-1] explodes
    return () unless @{ $self->messages };

    my %found;
    my $last = $self->messages->[-1]->uid;
    my $uids = $self->uids;
    for ( split ',', $str ) {
        if (/^(\d+):(\d+)$/) {
            @found{ $self->_uids_in_range( $1, $2 ) } = ();
        } elsif ( /^(\d+):\*$/ or /^\*:(\d+)$/ ) {
            $found{$last}++;
            @found{ $self->_uids_in_range( $1, $last ) } = ();
        } elsif (/^(\d+)$/) {
            $found{$_}++ if defined $uids->{$1};
        } elsif (/^\*$/) {
            $found{$last}++;
        }
    }
    return map { $uids->{$_} } sort { $a <=> $b } keys %found;
}

=head3 get_messages STR

Parses and returns messages fitting the given sequence range.  Note
that since sequence numbers are connection-dependent, this simply
passes the buck to L</Net::IMAP::Server::Connection/get_messages>.

=cut

sub get_messages {
    my $self = shift;
    return () unless Net::IMAP::Server->connection;
    return Net::IMAP::Server->connection->get_messages(@_);
}

=head3 update_tree

Called before the model's children are listed to the client.  This is
the right place to hook into for mailboxes whose children shift with
time.

=cut

sub update_tree {
    my $self = shift;
    $_->update_tree for @{ $self->children };
}

=head3 prep_for_destroy

Called before the mailbox is destroyed; this deals with cleaning up
the several circular references involved.  In turn, it calls
L</prep_for_destroy> on all child mailboxes, as well as all messages
it has.

=cut

sub prep_for_destroy {
    my $self = shift;
    my @kids = @{ $self->children || [] };
    $self->children( [] );
    $_->prep_for_destroy for @kids;
    my @messages = @{ $self->messages || [] };
    $self->messages( [] );
    $self->uids( {} );
    $_->prep_for_destroy for @messages;
    $self->parent(undef);
}

1;
