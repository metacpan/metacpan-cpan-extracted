package Net::IMAP::Server::DefaultModel;

use warnings;
use strict;

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(auth root));

use Net::IMAP::Server::Mailbox;

use Encode;
use Encode::IMAPUTF7;

my %roots;

=head1 NAME

Net::IMAP::Server::DefaultModel - Encapsulates per-connection
information about the layout of IMAP folders.

=head1 DESCRIPTION

This class represents an abstract model backend to the IMAP server; it
it meant to be overridden by server implementations.  Primarily,
subclasses are expected to override L</init> to set up their folder
structure.

Methods in the model can C<die> with messages which start with "NO" or
"BAD", which will be propagated back to the client immediately.  See
L<Net::IMAP::Server::Connection/handle_command>.

=head1 METHODS

=head2 new

This class is created when the client has successfully authenticated
to the server.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->init;
    return $self;
}

=head2 init

Called when the class is instantiated, with no arguments.  Subclasses
should override this method to inspect the L</auth> object, and
determine what folders the user should have.  The primary purpose of
this method is to set L</root> to the top level of the mailbox tree.
The root is expected to contain a mailbox named C<INBOX>.

=cut

sub init {
    my $self = shift;
    my $user = $self->auth->user || 'default';

    if ( $roots{$user} ) {
        $self->root( $roots{$user} );
    } else {
        $self->root( Net::IMAP::Server::Mailbox->new() )
            ->add_child( name => "INBOX" )
            ->add_child( name => $user );
        $roots{$user} = $self->root;
    }

    return $self;
}

=head2 root MAILBOX

Gets or sets the root L<Net::IMAP::Server::Mailbox> for this model.
The root mailbox should contain no messages, and have no name -- it
exists purely to contain sub-mailboxes, like C<INBOX>.  The L</init>
method is responsible for setting up the appropriate root mailbox, and
all sub-mailboxes for the model.

=head2 auth

Returns the L<Net::IMAP::Server::DefaultAuth> object for this model;
this is set by the connection when the model is created, and will
always reference a valid authentication object.

=head2 close

Called when this model's connection closes, for any reason.  By
default, does nothing.

=cut

sub close {
}

=head2 split PATH

Utility method which splits a given C<PATH> according to the mailbox
separator, as determined by the
L<Net::IMAP::Server::Mailbox/separator> of the L</root>.  May C<die>
if the path (which is expected to be encoded using IMAP-UTF-7) is
invalid.  See L<Encode::IMAPUTF7>. If the mailbox hierarchy is flat
(i.e. the separator is undef), returns the name without change.

=cut

sub split {
    my $self = shift;
    my $name = shift;

    $name = eval { Encode::decode('IMAP-UTF-7', $name) };
    die "BAD Invalid UTF-7 encoding\n" unless defined $name;

    if (defined $self->root->separator) {
        return grep {length} split quotemeta $self->root->separator, $name;
    } else {
        return $name;
    }
}

=head2 lookup PATH

Given a C<PATH>, returns the L<Net::IMAP::Server::Mailbox> for that
path, or undef if none matches.  May die if the path contains unvalid
IMAP-UTF-7 (see L</split>).

=cut

sub lookup {
    my $self  = shift;
    my $name  = shift;
    my @parts = $self->split($name);
    my $part  = $self->root;
    return undef unless @parts;
    while (@parts) {
        return undef unless @{ $part->children };
        my $find = shift @parts;
        my @match
            = grep { $_->is_inbox ? uc $find eq "INBOX" : $_->name eq $find }
            @{ $part->children };
        return undef unless @match;
        $part = $match[0];
    }
    return $part;
}

=head2 namespaces

Returns the namespaces of this model, per RFC 2342.  Defaults to
"INBOX" being the personal namespace, with no "shared" or "other
users" namespaces.

=cut

sub namespaces {
    my $self = shift;
    return ([["" => $self->root->separator]], undef, undef);
}

1;
