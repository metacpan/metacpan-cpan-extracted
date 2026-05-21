package TUI::Views::Palette;
# ABSTRACT: A class for managing color palettes

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TPalette
  new_TPalette
);

require bytes;
use TUI::toolkit qw( signature );
use TUI::toolkit::Types qw(
  is_Object
  :types
);

sub TPalette() { __PACKAGE__ }
sub new_TPalette { __PACKAGE__->from(@_) }

sub new {    # $obj (%args)
  state $sig = signature(
    method => 1,
    named => [
      data      => Str,               { optional => 1 },
      size      => PositiveOrZeroInt, { optional => 1 },
      copy_from => Object,            { optional => 1 },
    ],
  );
  my ( $class, $args ) = $sig->( @_ );
  my $data = "\0";
  if ( defined $args->{data} && defined $args->{size} ) {
    my $d   = $args->{data};
    my $len = $args->{size};
    $data = pack( 'C'.'a' x $len, $len, unpack( '(a)*', $d ) );
  }
  elsif ( defined $args->{copy_from} ) {
    my $tp = $args->{copy_from};
    $data = $$tp;
  }
  return bless \$data, $class;
}

sub from {    # $obj ($tp|$d, $len)
  if ( @_ > 2 ) {
    state $sig = signature(
      method => 1,
      pos    => [Str, PositiveOrZeroInt],
    );
    my ( $class, $d, $len ) = $sig->( @_ );
    return $class->new( data => $d, size => $len );
  } 
  else {
    state $sig = signature(
      method => 1,
      pos    => [Object],
    );
    my ( $class, $tp ) = $sig->( @_ );
    return $class->new( copy_from => $tp );
  }
}

sub clone {    # $clone ($self)
  state $sig = signature(
    method => 1,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $data = $$self;
  return bless \$data, ref $self;
}

sub assign {    # $self ($tp)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $self, $tp ) = $sig->( @_ );
  $$self = $$tp;
  return $self;
}

sub at {    # $byte ($index)
  state $sig = signature(
    method => 1,
    pos    => [Int],
  );
  my ( $self, $index ) = $sig->( @_ );
  return ord bytes::substr( $$self, $index, 1 );
}

use overload
  '@{}' => sub { [ unpack('C*', ${+shift}) ] },
  fallback => 1;

1

__END__

=pod

=head1 NAME

TUI::Views::Palette - color palette representation based on string data

=head1 HIERARCHY

  TPalette (scalar-based type)
    used by TView and derived classes

=head1 SYNOPSIS

  use TUI::Views;

  my $palette = TPalette->new(
    data => $data,
    size => length($data)
  );

  my $byte = $palette->at($index);

  my @colors = @{$palette};
  # @colors now contains the palette entries as integer values

=head1 DESCRIPTION

C<TPalette> represents a color palette as used by TUI::Vision views. Unlike
most TUI::Vision classes, C<TPalette> is not derived from C<TObject> and does
not use a hash-based object layout. Instead, it is conceptually based on scalar
string data.

This design mirrors the original Turbo Vision definition, where C<TPalette> is
simply a string type. Each character in the string represents a color entry.
The Perl implementation preserves this model while providing a small set of
object-style methods for convenience and compatibility.

Palette objects are typically created once and then shared or cloned by views
that require color information.

C<TPalette> supports array dereferencing through operator overloading.
Dereferencing a palette as an array returns a list of byte values representing
the palette entries.

=head1 CONSTRUCTOR

=head2 new

  my $palette = TPalette->new(
    data      => $data,
    size      => $size,
  );
  my $palette = TPalette->new(
    copy_from => $other
  );

Creates a new palette object.

=over

=item data

String containing the palette data. Used together with C<size> (I<Str>).

=item size

Number of entries in the palette (I<PositiveOrZeroInt>).

=item copy_from

Optional palette to copy data from. When provided, C<data> and C<size> are
ignored (I<TPalette>).

=back

=head2 new_TPalette

  my $palette = new_TPalette($data, $size);
  my $palette = new_TPalette($other);

Factory-style constructor using positional arguments.

This constructor forwards to the internal implementation and is provided for
compatibility with traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 assign

  $palette->assign($other);

Assigns the contents of another palette to this palette.

=head2 at

  my $byte = $palette->at($index);

Returns the palette entry at the specified index as an integer value.

=head2 clone

  my $copy = $palette->clone();

Creates and returns a clone of the palette.

=head1 SEE ALSO

L<TUI::Views::View>,
L<TUI::Views::PaletteConst>

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
