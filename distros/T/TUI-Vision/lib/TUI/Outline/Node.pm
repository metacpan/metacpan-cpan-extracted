package TUI::Outline::Node;
# ABSTRACT: node of an outline tree used by outline viewers

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TNode
  new_TNode
);

use Devel::StrictMode;
use if STRICT => 'Hash::Util';
use TUI::toolkit qw( :utils true );
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

sub TNode() { __PACKAGE__ }
sub new_TNode { __PACKAGE__->from(@_) }

# public attributes
our %HAS; BEGIN {
  %HAS = (
    text      => sub { '' },
    next      => sub { undef },
    childList => sub { undef },
    expanded  => sub { true },
  );
}

sub new {    # \$node (%args)
  state $sig = signature(
    method => 1,
    named  => [
      text      => Str,           { alias => 'aText' },
      childList => Maybe[Object], { alias => 'aChildren',    optional => 1 },
      next      => Maybe[Object], { alias => 'aNext',        optional => 1 },
      expanded  => Bool,          { alias => 'initialState', default => true },
    ],
  );
  my ( $class, $self ) = $sig->( @_ );
  $self->{$_} = $HAS{$_}->()
    for grep { not exists $self->{$_} } keys %HAS;
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub from {    # $node ($aText, |$aChildren|undef, |$aNext|undef, |$initialState)
  if (@_ == 2) {
    state $sig = signature(
      method => 1,
      pos    => [Str],
    );
    my ( $class, $text ) = $sig->( @_ );
    return $class->new( text => $text );
  }
  else {
    state $sig = signature(
      method => 1,
      pos    => [
        Str,
        Maybe[Object],
        Maybe[Object],
        Bool,          { default => true },
      ],
    );
    my ( $class, @args ) = $sig->( @_ );
    return $class->new( text => $args[0], childList => $args[1],
      next => $args[2], expanded => $args[3] );
  }
}

my $mk_accessors = sub {
  my ( $pkg ) = @_;
  assert ( @_ == 1 );
  assert ( defined $pkg );
  no strict 'refs';
  my %HAS = %{"${pkg}::HAS"};
  for my $field ( keys %HAS ) {
    my $full_name = "${pkg}::$field";
    *$full_name = sub {
      assert ( is_Object $_[0] );
      if ( @_ > 1 ) {
        $_[0]->{$field} = $_[1];
      }
      $_[0]->{$field};
    };
  }
};

__PACKAGE__->$mk_accessors();

1;

__END__

=pod

=head1 NAME

TUI::Outline::Node - node of an outline tree used by outline viewers

=head1 SYNOPSIS

  use TUI::toolkit;
  use TUI::Outline;
  my $root  = TNode->new(
    text      => 'Root',
    childList => $child,
    expanded  => false,
  );

  my $text = $root->text;             # "Root"
  my $kids = $root->childList;        # $child

=head1 DESCRIPTION

C<TNode> represents a single node of an outline tree as used by the
I<Turbo Vision> outline subsystem. Each node stores a text, a reference to its
first child (C<childList>), a reference to its next sibling (C<next>), and
whether it is currently expanded.

Trees are built by linking nodes through C<childList> and C<next>. A node with
no children has C<childList> set to C<undef>; the last sibling has C<next> set
to C<undef>.

Memory is managed automatically by Perl's reference counting, so no explicit
destructor or copy handling is required.

=head1 ATTRIBUTES

=head2 text

The text displayed for this node (I<Str>).

=head2 next

Reference to the next sibling node, or C<undef> (I<TNode> or undef).

=head2 childList

Reference to the first child node, or C<undef> if the node has no children
(I<TNode> or undef).

=head2 expanded

Whether the node is expanded, i.e. its children are shown (I<Bool>). Defaults
to true.

=head1 CONSTRUCTOR

=head2 new

  my $node = TNode->new(
    text      => $text,
    # optional
    (
      childList => $child | undef,    
      next      => $next  | undef,
      expanded  => $bool,
    )
  );

Creates a new C<TNode>. Only C<text> is required. The C<childList> and C<next>
arguments default to C<undef>, and C<expanded> defaults to true.

=head2 new_TNode

  my $node = new_TNode($text);
  my $node = new_TNode($text, $childList | undef, $next | undef);
  my $node = new_TNode($text, $childList | undef, $next | undef, $expanded);

Factory constructor that mirrors the positional I<Turbo Vision> constructor.
The trailing argument $expanded is optional and defaults to true. Called with
only C<$text>, it creates a node without children and without a next sibling,
and the node is expanded.

=head1 SEE ALSO

L<TOutlineViewer|TUI::Outline::OutlineViewer>,
L<TOutline|TUI::Outline::Outline>

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
