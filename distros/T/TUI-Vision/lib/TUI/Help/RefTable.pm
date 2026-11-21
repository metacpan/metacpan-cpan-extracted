package TUI::Help::RefTable;
# ABSTRACT: sorted symbol table of help-topic references

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TRefTable
  new_TRefTable
);

use Storable;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  is_Str
  :types
);

use TUI::Help::HelpBase;
use TUI::Objects::SortedCollection;

sub TRefTable() { __PACKAGE__ }
sub name() { 'TRefTable' }
sub new_TRefTable { __PACKAGE__->from(@_) }

extends TSortedCollection;

#
# TRefTable is a symbol table of TReference objects. Unseen topics create
# unresolved entries; previously seen topics retain their current values.
# Forward-reference fix-up lists are not represented in this port.
#
sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      limit => Int, { alias => 'aLimit' },
      delta => Int, { alias => 'aDelta' },
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
  $self->{shouldDelete} = true;
  return;
}

sub from {    # $table ($aLimit, $aDelta)
  state $sig = signature(
    method => 1,
    pos    => [Int, Int],
  );
  my ( $class, $aLimit, $aDelta ) = $sig->( @_ );
  return $class->new( limit => $aLimit, delta => $aDelta );
}

sub compare {    # $cmp ($key1, $key2)
  state $sig = signature(
    method => Object,
    pos    => [Str, Str],
  );
  my ( $self, $key1, $key2 ) = $sig->( @_ );
  return $key1 cmp $key2;
}

sub getReference {    # $reference ($topic)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $topic ) = $sig->( @_ );
  my $i;
  return $self->at( $i )
    if $self->search( $topic, \$i );

  my $ref = TReference->new(
    topic    => $topic,
    resolved => false,
    val      => 0,
  );
  $self->insert( $ref );
  return $ref;
}

sub keyOf {    # $topic ($item)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $item ) = $sig->( @_ );
  return $item->topic;
}

sub readItem {    # undef ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  assert ( Storable::is_retrieving );
  return undef;
}

sub writeItem {    # void ($item, $os)
  state $sig = signature(
    method => Object,
    pos    => [Item, Object],
  );
  my ( $self, $item, $os ) = $sig->( @_ );
  assert ( Storable::is_storing );
  return;
}

sub build {    # $table ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new( limit => 0, delta => 0 );
}

1

__END__

=pod

=head1 NAME

TUI::Help::RefTable - sorted symbol table of help-topic references

=head1 HIERARCHY

  TObject
    TNSCollection
      TNSSortedCollection
        TSortedCollection
          TRefTable

=head1 SYNOPSIS

  use TUI::Help;

  my $table = new_TRefTable( 10, 5 );
  my $reference = $table->getReference( 'Introduction' );
  $reference->val( 100 );
  $reference->resolved( 1 );

  my $same = $table->getReference( 'Introduction' );
  my $value = $same->val();

=head1 DESCRIPTION

C<TRefTable> ports the topic-reference symbol table of the original Borland
help compiler. It stores the C<TReference> records defined by
L<TUI::Help::HelpBase> in case-sensitive topic-name order.

Looking up a known name returns its existing record. An unknown name
creates a record with that topic name, C<resolved> false, and C<val> zero.
Callers supply the numeric value and mark the reference resolved.

Only numeric values are represented. The original forward-reference
fix-up lists are not supported. Initializing C<val> to zero is the
numeric-only adaptation of the original empty fix-up list.

The item-streaming methods are empty, as in the original: no reference
records are written, and reading an item returns C<undef>. Storable
therefore preserves only the inherited collection metadata. Restoring a
nonempty table produces undefined entries, not a usable symbol table.
The inherited streaming machinery uses L<TStream|TUI::Objects::Stream> objects,
not filehandles.

=head2 Commonly Used Features

Use the table to collect references while processing help topics. Keep the
record returned by C<getReference>, then fill in its numeric value when the
topic is defined. Later lookups reuse the updated record. Do not change
the topic name of an inserted record, as this would invalidate its sorted
position.

=head1 CONSTRUCTOR

=head2 new

  my $table = TRefTable->new( limit => 10, delta => 5 );

Creates an empty table. Both arguments are required:

=over

=item limit

C<Int>. Initial collection capacity. The alias C<aLimit> is accepted.

=item delta

C<Int>. Collection growth increment. The alias C<aDelta> is accepted.

=back

=head2 new_TRefTable

  my $table = new_TRefTable( 10, 5 );

Positional factory taking the initial capacity and growth increment.

=head1 METHODS

Collection access, search, insertion, and removal are inherited from
L<TSortedCollection|TUI::Objects::SortedCollection> and L<TNSCollection|TUI::Objects::NSCollection>.

=head2 compare

  my $order = $table->compare( $key1, $key2 );

Compares two C<Str> topic names case-sensitively. Returns C<-1>, C<0>,
or C<1> for less than, equal to, or greater than, respectively.

=head2 getReference

  my $reference = $table->getReference( $topic );

Accepts a C<Str> topic name and returns its C<TReference> object, creating
an unresolved record if necessary. Repeated lookups of the same name
return the same object without resetting its fields. Names differing
only in case identify distinct records.

=head2 keyOf

  my $topic = $table->keyOf( $item );

Returns the C<Str> topic name of a C<TReference> object.

=head1 SEE ALSO

L<TUI::Help>, L<TUI::Help::HelpBase>,
L<TSortedCollection|TUI::Objects::SortedCollection>, L<TNSCollection|TUI::Objects::NSCollection>,
L<TUI::toolkit::Types>

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
