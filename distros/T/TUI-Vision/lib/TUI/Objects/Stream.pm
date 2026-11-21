package TUI::Objects::Stream;
# ABSTRACT: defines the class TStream

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStream
  new_TStream
);

use Hash::Util::FieldHash qw(
  fieldhash
  id
);
use Scalar::Util qw(
  blessed
  weaken
);
use Storable qw(
  freeze
  thaw 
);

use PerlX::Assert::PP;
use TUI::toolkit::Types qw(
  is_Object
  is_Str
);
use TUI::Objects::Streamable;

sub TStream() { __PACKAGE__ }
sub new_TStream { __PACKAGE__->new(@_) }

use constant {
  ptObject  => 'TUI::Objects::Stream::ptObject',
  ptIndexed => 'TUI::Objects::Stream::ptIndexed',
};

#
# Maintains a process-local database of streamable objects that have
# been packed and are still alive.
#
# Used to detect repeated references across nested object streams.
#
fieldhash my %writtenObjects;

#
# Maps persisted object identifiers to retrieved objects.
#
# Values are weak references so that this registry does not control
# the lifetime of restored objects.
#
my %readObjects;

sub new {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  return bless [], $class;
}

sub put {    # $self (@values)
  my ( $self, @values ) = @_;
  assert ( @_ >= 1 );
  assert ( is_Object $self );

  for my $value ( @values ) {
    if ( blessed $value && $value->DOES( TStreamable ) ) {
      my $id = $writtenObjects{$value} // 0;

      if ( $id ) {
        $value = bless \$id => ptIndexed;
      }
      else {
        $id = id $value;
        $writtenObjects{$value} = $id;
        $value = bless [ 
          $id, 
          freeze $value 
        ] => ptObject;
      }
    }

    push @$self, $value;
  }

  return $self;
}

sub get {    # $value ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );

  my $value = shift @$self;

  return $value
    unless blessed $value;

  if ( $value->isa( ptIndexed ) ) {
    my $id = $$value;
    return $readObjects{$id};
  }

  if ( $value->isa( ptObject ) ) {
    my ( $id, $data ) = @$value;
    my $ref = thaw $data;
    $readObjects{$id} = $ref;
    weaken $readObjects{$id};
    return $ref;
  }

  return $value;
}

1;

__END__

=pod

=head1 NAME

TUI::Objects::Stream - sequential stream for object serialization

=head1 SYNOPSIS

  use TUI::Objects::Stream;

  my $stream = new_TStream();

  $stream->put( 10, 20, 30 );

  my $x = $stream->get();
  my $y = $stream->get();
  my $z = $stream->get();

=head1 DESCRIPTION

C<TStream> provides a lightweight sequential stream used by the Turbo Vision
object persistence mechanism. Values are written with L</put> and read in the
same order with L</get>.

The interface follows the C<put> and C<get> operations of Pascals's Turbo
Vision stream abstraction while operating on Perl values. It is used by the
C<write> and C<read> methods of persistent framework objects.

Objects performing the L<TStreamable|TUI::Objects::Streamable> role participate
in the Turbo Vision object streaming mechanism. C<TStream> tracks object
identity so that repeated references to the same object are resolved to the
same reconstructed object when read back. This preserves shared references
while the framework rebuilds the Turbo Vision object graph through its
C<write> and C<read> methods.

=head1 CONSTRUCTOR

=head2 new

  my $stream = TStream->new();

Creates and returns an empty stream.

=head2 new_TStream

  my $stream = new_TStream();

Creates and returns an empty C<TStream> using the Turbo Vision style factory
function.

=head1 METHODS

=head2 get

  my $value = $stream->get();

Removes and returns the next value from the stream.

Values are returned in the same order in which they were written with
L</put>. References to previously read L<TStreamable|TUI::Objects::Streamable>
objects are resolved to the corresponding reconstructed object, preserving
object identity within the restored Turbo Vision object graph.

=head2 put

  $stream->put(@values);

Writes one or more values to the stream in the order given and returns the
stream object.

C<TStream> tracks the identity of L<TStreamable|TUI::Objects::Streamable> 
objects. The first occurrence carries the object's persistent representation, 
while subsequent references are recorded so that they can be resolved to the 
same reconstructed object by L</get>. Other values are stored unchanged.

=head1 SEE ALSO

L<TStreamable|TUI::Objects::Streamable>,
L<TUI::Manual::09>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
