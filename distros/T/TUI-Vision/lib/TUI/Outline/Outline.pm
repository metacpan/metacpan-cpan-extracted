package TUI::Outline::Outline;
# ABSTRACT: outline viewer that displays a tree of TNode objects

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TOutline
  new_TOutline
);

use Storable;

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Objects::Rect;
use TUI::Outline::Node;
use TUI::Outline::OutlineViewer;

sub TOutline() { __PACKAGE__ }
sub name() { 'TOutline' }
sub new_TOutline { __PACKAGE__->from(@_) }

extends TOutlineViewer;

# public attributes
has root => ( is => 'rw' );


sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      hScrollBar => Maybe[Object], { alias => 'aHScrollBar' },
      vScrollBar => Maybe[Object], { alias => 'aVScrollBar' },
      root       => Maybe[Object], { alias => 'aRoot' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->update();
  return;
}

sub from {    # $outline ($bounds, $aHScrollBar|undef, $aVScrollBar|undef, $aRoot)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[Object], Maybe[Object], Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], hScrollBar => $args[1],
    vScrollBar => $args[2], root => $args[3] );
}

sub adjust {    # void ($node, $expand)
  state $sig = signature(
    method => Object,
    pos    => [Object, Bool],
  );
  my ( $self, $node, $expand ) = $sig->( @_ );
  $node->expanded( $expand );
  return;
}

sub getRoot {    # $node ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->root;
}

sub getNumChildren {    # $count ($node)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $node ) = $sig->( @_ );
  my $count = 0;
  my $p     = $node->childList;
  while ( $p ) {
    $count++;
    $p = $p->next;
  }
  return $count;
}

sub getChild {    # $node ($node, $i)
  state $sig = signature(
    method => Object,
    pos    => [Object, Int],
  );
  my ( $self, $node, $i ) = $sig->( @_ );
  my $p = $node->childList;
  while ( $i != 0 && $p ) {
    $i--;
    $p = $p->next;
  }
  return $p;
}

sub getText {    # $text ($node)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $node ) = $sig->( @_ );
  return $node->text;
}

sub isExpanded {    # $bool ($node)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $node ) = $sig->( @_ );
  return $node->expanded;
}

sub hasChildren {    # $bool ($node)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $node ) = $sig->( @_ );
  return defined $node->childList ? true : false;
}

sub write :method {    # void ($os)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $os ) = $sig->( @_ );
  $self->SUPER::write( $os );
  my $root = $self->root;
  $os->put( defined $root ? 1 : 0 );
  $self->writeNode( $root, $os ) if defined $root;
  return;
}

sub read :method {    # $self ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  $self->SUPER::read( $is );
  my $hasRoot = $is->get();
  $self->root( $hasRoot ? $self->readNode( $is ) : undef );
  return $self;
}

sub writeNode {    # void ($node, $os)
  state $sig = signature(
    method => Object,
    pos    => [Object, Object],
  );
  my ( $self, $node, $os ) = $sig->( @_ );

  my $more   = defined $node->next ? 1 : 0;
  my $expand = $node->expanded ? 1 : 0;
  $os->put( 
    $more, 
    $expand, 
    $self->getNumChildren( $node ), 
    $node->text
  );

  $self->writeNode( $node->childList, $os )
    if defined $node->childList;
  $self->writeNode( $node->next, $os )
    if defined $node->next;
  return;
}

sub readNode {    # $node ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );

  my $more      = $is->get();
  my $expand    = $is->get() ? true : false;
  my $nChildren = $is->get();
  my $text      = $is->get();

  my $childList = $nChildren 
    ? $self->readNode( $is ) 
    : undef;
  my $next = $more 
    ? $self->readNode( $is )
    : undef;

  return TNode->new(
    text      => $text,
    childList => $childList,
    next      => $next,
    expanded  => $expand,
  );
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new(
    bounds     => TRect->new(),
    hScrollBar => undef,
    vScrollBar => undef,
    root       => undef,
  );
}

1;

__END__

=head1 NAME

TUI::Outline::Outline - outline viewer that displays a tree of TNode objects

=head1 HIERARCHY

  TObject
    TView
      TScroller
        TOutlineViewer
          TOutline

=head1 SYNOPSIS

  use TUI::toolkit;
  use TUI::Objects;
  use TUI::Outline;
  use TUI::Views;
  my $root    = TNode->new(
    text      => 'Root',
    childList => $child,
    expanded  => true,
  );
  my $outline = TOutline->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 10 ),
    hScrollBar => undef,
    vScrollBar => undef,
    root       => $root,
  );

=head1 DESCRIPTION

C<TOutline> is the concrete outline viewer of the I<Turbo Vision> outline
subsystem. It displays the tree of L<TNode|TUI::Outline::Node> objects that
starts at its C<root> node and implements the abstract methods of
L<TOutlineViewer|TUI::Outline::OutlineViewer> on top of the node attributes.

The constructor updates the viewer, so the outline is ready to draw after
creation. Expanding or retracting a node changes its C<expanded> attribute.

The tree is freed by Perl reference counting. Streaming is supported through
Storable serialization, which writes the node tree as a flat sequence of
primitive values; the root is preceded by a presence flag, since an empty
outline has no root node to write.

=head1 ATTRIBUTES

=head2 root

The root node of the outline tree (L<TNode|TUI::Outline::Node>), or C<undef>
for an empty outline.

=head1 CONSTRUCTOR

=head2 new

  my $outline = TOutline->new(
    bounds     => $bounds,
    hScrollBar => $hScrollBar,
    vScrollBar => $vScrollBar,
    root       => $root,
  );

Creates a new outline viewer for the tree that starts at C<root>.

=over

=item bounds

Bounding rectangle of the outline viewer (L<TRect|TUI::Objects::Rect>).

=item hScrollBar

Optional horizontal scroll bar (L<TScrollBar|TUI::Views::ScrollBar> or
C<undef>).

=item vScrollBar

Optional vertical scroll bar (L<TScrollBar|TUI::Views::ScrollBar> or C<undef>).

=item root

Root node of the outline tree (L<TNode|TUI::Outline::Node> or C<undef> for an
empty outline).

=back

=head2 new_TOutline

  my $outline = new_TOutline($bounds, $hScrollBar | undef,
    $vScrollBar | undef, $root);

Factory constructor that mirrors the positional I<Turbo Vision> constructor.

=head1 METHODS

=head2 adjust

  $outline->adjust($node, $expand);

Sets the C<expanded> attribute of C<$node> to C<$expand>.

=head2 getChild

  my $child = $outline->getChild($node, $i);

Returns the child of C<$node> at index C<$i>, counting from 0, or C<undef> if
there is no such child.

=head2 getNumChildren

  my $count = $outline->getNumChildren($node);

Returns the number of children of C<$node>.

=head2 getRoot

  my $root = $outline->getRoot();

Returns the root node of the outline tree, or C<undef> if the outline is empty.

=head2 getText

  my $text = $outline->getText($node);

Returns the text of C<$node>.

=head2 hasChildren

  my $bool = $outline->hasChildren($node);

Returns true if C<$node> has at least one child.

=head2 isExpanded

  my $bool = $outline->isExpanded($node);

Returns the C<expanded> attribute of C<$node>.

=head1 SEE ALSO

L<TNode|TUI::Outline::Node>,
L<TOutlineViewer|TUI::Outline::OutlineViewer>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
