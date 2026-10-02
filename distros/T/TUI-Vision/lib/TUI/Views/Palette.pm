package TUI::Views::Palette;
# ABSTRACT: A class for managing color palettes

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TPalette
  new_TPalette
);

require bytes;
use TUI::toolkit qw( assert signature );
use TUI::toolkit::Types qw(
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
      copy_from => ArrayLike,         { optional => 1 },
    ],
  );
  my ( $class, $args ) = $sig->( @_ );
  my @data = ( 0 );
  if ( defined $args->{data} && defined $args->{size} ) {
    my $len = $args->{size};
    $data[0] = $len;
    @data[ 1 .. $len ] = unpack "(C)$len", $args->{data};
    $_ //= 0 for @data;
  }
  elsif ( defined $args->{copy_from} ) {
    my $tp = $args->{copy_from};
    assert ( $tp->[0] == @$tp - 1 );
    @data = @$tp;
  }
  return bless \@data, $class;
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
      pos    => [ArrayLike],
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
  my @data = @$self;
  return bless \@data, ref $self;
}

sub assign {    # $self ($tp)
  state $sig = signature(
    method => 1,
    pos    => [ArrayLike],
  );
  my ( $self, $tp ) = $sig->( @_ );
  assert ( $tp->[0] == @$tp - 1 );
  @$self = @$tp;
  return $self;
}

sub at {    # $entry ($index)
  state $sig = signature(
    method => 1,
    pos    => [Int],
  );
  my ( $self, $index ) = $sig->( @_ );
  assert ( $index >= 0 && $index <= @$self );
  return $self->[$index];
}

1

__END__

=pod

=head1 NAME

TUI::Views::Palette - color palette representation based on string data

=head1 SYNOPSIS

  use TUI::Views;

  my $palette = TPalette->new(
    data => "\x01\x02\x03",
    size => 3,
  );

  my $len   = $palette->at(0);  # 3
  my $first = $palette->at(1);  # ord("\x01")

  my @entries = @{$palette};    # length-prefixed palette data

  my $copy = TPalette->new(
    copy_from => \@data
  );

  my @data = @{$copy};

  my $other = TPalette->new(
    copy_from => [
      3,
      TColorAttr->new( bios => 0x01 ),
      TColorAttr->new( bios => 0x02 ),
      TColorAttr->new( bios => 0x03 ),
    ]
  );

  my @attr = @{$other};         # palette entries as TColorAttr objects

=head1 DESCRIPTION

C<TPalette> represents a color palette as used by L<TUI::Vision> views. Unlike 
most L<TUI::Vision> classes, C<TPalette> is not derived from 
L<TObject|TUI::Objects::Object>.

The original L<TUI::Vision> implementation stored a palette as a length-prefixed
Pascal string. For compatibility, the Perl port preserves the same logical
layout while using an array-based object representation internally:

  [ count, entry1, entry2, ... ]

Element C<[0]> contains the number of palette entries and palette data begins
at index C<1>.

Palette objects are typically created once and then shared or cloned by views
that require color information.

Palette entries are commonly integer attribute values obtained from string
data, but may also be arbitrary objects such as instances of 
L<TColorAttr|TUI::Drivers::ColorAttr>.

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

Optional palette to copy data from (I<TPalette>). Ignored when C<data> and 
C<size> are provided.

=back

=head2 new_TPalette

  my $palette = new_TPalette($data, $size);
  my $palette = new_TPalette($other);

Factory-style constructor using positional arguments.

This constructor forwards to the internal implementation and is provided for
compatibility with traditional I<Turbo Vision> construction patterns.

=head1 METHODS

=head2 assign

  $palette->assign($other);

Assigns the contents of another palette to this palette.

=head2 at

  my $entry = $palette->at($index);

Returns the palette entry at the specified index as an integer value.

=head2 clone

  my $copy = $palette->clone();

Creates and returns a clone of the palette.

=head1 SEE ALSO

L<TView|TUI::Views::View>,
L<TPalette|TUI::Views::Palette>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

=over

=item * magiblot <magiblot@hotmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2019-2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
