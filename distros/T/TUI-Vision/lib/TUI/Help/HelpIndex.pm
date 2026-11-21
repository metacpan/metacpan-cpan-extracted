package TUI::Help::HelpIndex;
# ABSTRACT: help context position index

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;

our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  THelpIndex
  new_THelpIndex
);

use Storable qw( freeze thaw );
use TUI::toolkit;
use TUI::toolkit::Types qw( :is :types );
use TUI::Objects::Object;
use TUI::Objects::Stream;
use TUI::Objects::Streamable;

sub THelpIndex() { __PACKAGE__ }
sub name() { 'THelpIndex' };
sub new_THelpIndex { __PACKAGE__->from(@_) }

extends TObject;
with: *DOES = TStreamable->can('DOES');

# public attributes
has size  => ( is => 'bare', default => 0 );
has index => ( is => 'rw', default => sub { [] } );

sub position {    # $position ($i)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $i ) = $sig->( @_ );
  assert ( $i >= 0 );

  if ( $i < $self->size ) {
    return $self->{index}[$i];
  }
  else {
    return -1;
  }
}

sub add {    # void ($i, $val)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $i, $val ) = $sig->( @_ );
  assert ( $i >= 0 );

  my $delta = 10;
  my $size = $self->size;
  if ( $i >= $size ) {
    my $newSize = int( ( $i + $delta ) / $delta ) * $delta;
    push @{ $self->{index} }, ( -1 ) x ( $newSize - $size );
  }

  $self->{index}[$i] = $val;

  return;
}

sub size {    # $size ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{size} = scalar @{ $self->{index} };
  return $self->{size};
}

sub STORABLE_freeze {    # @list ($cloning)
  my ( $self, $cloning ) = @_;
  assert ( is_Object $self );
  assert ( is_Bool $cloning );
  assert ( not $cloning );

  my $stream = TStream->new();
  $self->write( $stream );
  return freeze $stream;
}

sub STORABLE_attach {    # $obj ($cloning, $serialized)
  my ( $class, $cloning, $serialized ) = @_;
  assert ( is_Str $class );
  assert ( is_Bool $cloning );
  assert ( is_Str $serialized );
  assert ( not $cloning );

  my $self = $class->build();
  my $stream = thaw $serialized;
  return $self->read( $stream );
}

sub write :method {    # void ($os)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $os ) = $sig->( @_ );
  assert ( Storable::is_storing );
  $os->put( $self->size, @{ $self->{index} } );
  return;
}

sub read :method {    # $self ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  assert ( Storable::is_retrieving );
  my $size = $is->get();
  $self->{index} = [ map { $is->get() } 1 .. $size ];
  return $self;
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new();
}

1

__END__

=pod

=head1 NAME

TUI::Help::HelpIndex - help context position index

=head1 HIERARCHY

  TObject
    THelpIndex

=head1 SYNOPSIS

  use TUI::Help;

  my $index = new_THelpIndex();

  $index->add( 2, 120 );
  $index->add( 14, 940 );

  my $position = $index->position( 14 );

=head1 DESCRIPTION

C<THelpIndex> maps numeric help contexts to positions in a compiled help
file.

The class follows the Turbo Vision context-index behavior, using a Perl
array for storage. It supports C<Storable> persistence through
L<TStreamable|TUI::Objects::Streamable> and L<TStream|TUI::Objects::Stream>, preserving every
allocated slot, including unused entries.

Contexts without a recorded position return C<-1>.

Context arguments have type C<Int>, but callers must supply non-negative
values. Assertions check this precondition when enabled.

=head2 Commonly Used Features

Add a file position for a help context with L</add>, then retrieve that
position with L</position>. The index grows automatically when a context
outside the current range is added.

=head1 ATTRIBUTES

=head2 index

Array reference I<ArrayRef[Int]> containing help-file positions indexed
by help context.

Initially empty. Growth allocates slots in blocks of ten and initializes
new entries to C<-1>. The existing array reference is retained during growth.

=head1 CONSTRUCTOR

=head2 new

  my $index = THelpIndex->new();

Creates an empty help index.

=head2 new_THelpIndex

  my $index = new_THelpIndex();

Positional factory for L</new>.

=head1 METHODS

=head2 add

  $index->add( $i, $val );

Records position C<$val> for context C<$i>.

If C<$i> is beyond the current size, the index grows to the smallest
multiple of ten greater than C<$i>. Existing entries are preserved;
new entries are initialized to C<-1> before recording the position.

C<$i> must be non-negative; an assertion checks this precondition.

=head2 position

  my $position = $index->position( $i );

Returns the position recorded for context C<$i>.

Returns C<-1> when the context is outside the current index or does not yet
have a recorded position.

C<$i> must be non-negative; an assertion checks this precondition.

=head2 size

  my $size = $index->size();

Returns the number of allocated index slots as C<PositiveOrZeroInt>,
computed from the current index array on each call.

=head1 SEE ALSO

L<TUI::Help>, L<THelpFile|TUI::Help::HelpFile>, L<TObject|TUI::Objects::Object>

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
