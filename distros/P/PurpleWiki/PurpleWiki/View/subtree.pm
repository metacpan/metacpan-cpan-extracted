package PurpleWiki::View::subtree;
use 5.005;
use strict;
use warnings;
use Carp;
use PurpleWiki::View::Driver;

############### Package Globals ###############

our $VERSION;
$VERSION = sprintf("%d", q$Id: subtree.pm 366 2004-05-19 19:22:17Z eekim $ =~ /\s(\d+)\s/);

our @ISA = qw(PurpleWiki::View::Driver);


############### Overloaded Methods ###############

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    croak "No nid given to PurpleWiki::View::subtree->new()"
        unless defined $self->{nid};

    # Object State
    $self->{subtree} = undef;

    bless($self, $class);
    return $self;
}

sub view {
    my ($self, $wikiTree) = @_;
    $self->{subtree} = undef;  # Reset in case we're passed in a new tree
    $self->SUPER::view($wikiTree);
    return $self->{subtree};
}

sub getSubTree {
    my $self = shift;
    return $self->{subtree};
}

sub recurse {
    my $self = shift;
    return if $self->{subtree};  # Bail fast if we found our NID.
    $self->SUPER::recurse(@_);
}

sub traverse {
    my $self = shift;
    return if $self->{subtree};  # Bail fast if we found our NID.
    $self->SUPER::traverse(@_);
}

sub Post {
    my ($self, $nodeRef) = @_;
    if ($nodeRef->isa('PurpleWiki::StructuralNode') and defined $nodeRef->id) {
        if ($nodeRef->id eq $self->{nid}) {
            $self->{subtree} = $nodeRef;
        }
    }
}
1;
__END__

=head1 NAME

PurpleWiki::View::subtree - Extracts a Subtree Rooted at a Given NID.

=head1 SYNOPSIS

    See get() in Transclusion.pm

=head1 DESCRIPTION

Subtree extracts a subtree rooted at a node with a given NID.  It's useful
for doing transclusion or removing slices from a tree.

=head1 METHODS

=head2 new(nid => $nid)

Returns a new PurpleWiki::View::subtree object.

nid is a PurpleWiki NID for the given node you're searching for.  It is an
error to not supply nid.

=head2 view($tree)

Returns a subtree of $tree with the root node of subtree being a node with
the NID passed into new().  $tree is a PurpleWiki::Tree.

=head2 getSubTree(void)

Returns the subtree found by the call view().  Returns undef if view() hasn't
been called yet.

=head1 AUTHORS

Matthew O'Connor, E<lt>matthew@canonical.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::View::Driver>

=cut
