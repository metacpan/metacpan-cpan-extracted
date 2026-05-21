package TUI::Dialogs::StrItem;
# ABSTRACT: Simple singly linked list node for dialog data

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TSItem
  new_TSItem
);

use Devel::StrictMode;
use if STRICT => 'Hash::Util';
use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

sub TSItem() { __PACKAGE__ }
sub new_TSItem { __PACKAGE__->from(@_) }

# public attributes
our %HAS; BEGIN {
  %HAS = (
    value => sub { '' },
    next  => sub { undef },
  );
}

sub new {    # \$item (%args)
  state $sig = signature(
    method => 1,
    named  => [
      value => Str,
      next  => Maybe[Object],
    ],
  );
  my ( $class, $self ) = $sig->( @_ );
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub from {    # $item ($aValue, $aNext|undef)
  state $sig = signature(
    method => 1,
    pos    => [Str, Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( value => $args[0], next => $args[1] );
}

my $mk_ro_accessors = sub {
  my ( $pkg ) = @_;
  assert ( @_ == 1 );
  assert ( defined $pkg );
  no strict 'refs';
  my %HAS = %{"${pkg}::HAS"};
  for my $field ( keys %HAS ) {
    my $full_name = "${pkg}::$field";
    *$full_name = sub {
      assert ( @_ == 1 );
      assert ( is_Object $_[0] );
      $_[0]->{$field};
    };
  }
};

__PACKAGE__->$mk_ro_accessors();

1;

__END__

=pod

=head1 NAME

TSItem - simple singly linked list node for  dialog data

=head1 SYNOPSIS

  use TUI::Dialogs;

  my $item3 = TSItem->new( value => "third",  next => undef );
  my $item2 = TSItem->new( value => "second", next => $item3 );
  my $item1 = TSItem->new( value => "first",  next => $item2 );

  my $value = $item1->value;   # "first"
  my $next  = $item1->next;    # $item2

=head1 DESCRIPTION

C<TSItem> represents a minimal singly linked list node used by TUI::Vision
dialog infrastructure. Each node stores a string value and a reference to the
next node in the list, or C<undef> if it is the last element.

This structure originates from the classic Turbo Vision record type used for
managing lists of strings. In the Perl implementation, it benefits from
automatic memory management and reference handling while preserving the
original data model.

C<TSItem> is typically created indirectly by helper functions or higher-level
dialog components and is rarely manipulated directly in application code.

=head1 DISCUSSION

Linked lists of C<TSItem> objects are commonly used to represent collections of
dialog-related strings, such as option lists or input histories. Each node
contains only the essential information required to traverse the list, keeping
the structure lightweight and efficient.

Unlike container abstractions such as arrays, C<TSItem> mirrors the original
Turbo Vision design closely, which simplifies porting and maintenance of
existing logic.

=head1 ATTRIBUTES

=over

=item value

The string value stored in this list node (I<Str>).

=item next

Reference to the next node in the list, or C<undef> if this is the last element
(I<TSItem> or undef).

=back

=head1 METHODS

=head2 new

  my $item = TSItem->new(value => $value, next => $next);

Creates a new C<TSItem> node with the specified string value and an optional
reference to the next node.

=over

=item value

The string value to be stored in the node (I<Str>).

=item next

Reference to the next C<TSItem> in the list, or C<undef> (I<TSItem> or undef).

=back

=head2 new_TSItem

  my $item = new_TSItem($aValue, $aNext | undef);

Factory constructor that creates a new list element from a string value and a
reference to the next node.

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
