package TUI::Views::DrawBuffer;
# ABSTRACT: TDrawBuffer stores a line of text for output in views

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDrawBuffer
  new_TDrawBuffer
);

use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw(
  :is
  :types
);

sub TDrawBuffer() { __PACKAGE__ }
sub new_TDrawBuffer { __PACKAGE__->from(@_) }

use TUI::Views::Const qw( maxViewWidth );

my $setAttr = sub {    # void ($cell, $attr)
  assert ( @_ == 2 );
  assert ( is_PositiveOrZeroInt $_[0] );
  assert ( is_PositiveOrZeroInt $_[1] );
  $_[0] = ( ( $_[1] & 0xff ) << 8 ) | $_[0] & 0xff;
  return;
};

my $getChar = sub {    # $ch ($cell)
  assert ( @_ == 1 );
  assert ( is_PositiveOrZeroInt $_[0] );
  $_[0] & 0xff;
};

my $setChar = sub {    # void ($cell, $ch)
  assert ( @_ == 2 );
  assert ( is_PositiveOrZeroInt $_[0] );
  assert ( is_PositiveOrZeroInt $_[1] );
  $_[0] = $_[0] & 0xff00 | $_[1] & 0xff;
  return;
};

my $setCell = sub {    # void ($cell, $ch, $attr)
  assert ( @_ == 3 );
  assert ( is_PositiveOrZeroInt $_[0] );
  assert ( is_PositiveOrZeroInt $_[1] );
  assert ( is_PositiveOrZeroInt $_[2] );
  $_[0] = ( ( $_[2] & 0xff ) << 8 ) | $_[1] & 0xff;
  return;
};

sub new {    # $obj ()
  state $sig = signature(
    method => 1,
    pos    => [],
  );
  my ( $class ) = $sig->( @_ );
  my $self  = [ ( 0 ) x maxViewWidth ];
  return bless $self, $class;
}

sub from {    # $obj ()
  goto &new;
}

sub putAttribute {    # void ($indent, $attr)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $self, $indent, $attr ) = $sig->( @_ );
  &$setAttr( $self->[$indent], $attr );
  return;
}

sub putChar {    # void ($indent, $c)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Str],
  );
  my ( $self, $indent, $c ) = $sig->( @_ );
  assert ( length $c );
  &$setChar( $self->[$indent], ord( $c ) );
  return;
}

sub moveBuf {    # void ($indent, \@source, $attr, $count)
  state $sig = signature(
    method => Object,
    pos    => [
      PositiveOrZeroInt, 
      ArrayLike, 
      PositiveOrZeroInt, 
      PositiveOrZeroInt,
    ],
  );
  my ( $self, $indent, $source, $attr, $count ) = $sig->( @_ );

  if ( $attr ) {
    for ( my $i = 0 ; $i < $count ; $i++ ) {
      &$setCell( $self->[ $indent + $i ], &$getChar( $source->[$i] ), $attr );
    }
  }
  else {
    for ( my $i = 0 ; $i < $count ; $i++ ) {
      $self->[ $indent + $i ] = $source->[$i];
    }
  }
  return;
} #/ sub moveBuf

sub moveChar {    # void ($indent, $c, $attr, $count)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Str, PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $self, $indent, $c, $attr, $count ) = $sig->( @_ );
  assert ( length $c );

  my $dest = $indent;
  while ( $count-- ) {
    if ( $attr ) {
      if ( $c ) {
        &$setCell( $self->[ $dest++ ], ord( $c ), $attr );
      } 
      else {
        &$setAttr( $self->[ $dest++ ], $attr );
      }
    }
    else {
      &$setChar( $self->[ $dest++ ], ord( $c ) );
    }
  }
  return;
} #/ sub moveChar

sub moveCStr {    # void ($indent, $str, $attrs)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Str, PositiveOrZeroInt],
  );
  my ( $self, $indent, $str, $attrs ) = $sig->( @_ );
  my $toggle  = 1;
  my $curAttr = $attrs & 0xff;

  my $dest = $indent;
  foreach my $c ( split //, $str ) {
    if ( $c eq '~' ) {
      $curAttr = ( $attrs >> ( 8 * $toggle ) ) & 0xff;
      $toggle  = 1 - $toggle;
    }
    else {
      &$setCell( $self->[ $dest++ ], ord( $c ), $curAttr );
    }
  } #/ foreach my $c ( split //, $str)
  return;
} #/ sub moveCStr

sub moveStr {    # void ($indent, $str, $attrs)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Str, PositiveOrZeroInt],
  );
  my ( $self, $indent, $str, $attrs ) = $sig->( @_ );

  my $dest = $indent;
  foreach my $c ( split //, $str ) {
    if ( $attrs ) {
      &$setCell( $self->[ $dest++ ], ord( $c ), $attrs );
    }
    else {
      &$setChar( $self->[ $dest++ ], ord( $c ) );
    }
  }
}

1

__END__

=pod

=head1 NAME

TDrawBuffer - temporary line buffer for screen output

=head1 HIERARCHY

  TDrawBuffer (value type)
    used by TView drawing methods

=head1 SYNOPSIS

  use TUI::Views;

  my $buffer = TDrawBuffer->new;

  $buffer->moveStr(
    0,
    'Financial Results for FY1991',
    $view->getColor(1)
  );

  $view->writeLine(1, 3, 28, 1, $buffer);

=head1 DESCRIPTION

C<TDrawBuffer> represents a temporary buffer for rendering a single line of
screen output. Each entry in the buffer stores both a character value and a
display attribute.

This type is a lightweight value type and is not derived from C<TObject>.
Internally, it corresponds to an array of fixed width, where each element
combines a character and its visual attributes.

C<TDrawBuffer> is primarily used inside C<TView> drawing routines. Text and
attributes are written into the buffer using helper methods, and the buffer is
then passed to C<TView> methods such as C<writeLine> or C<writeBuf> to render the
output on screen.

=head1 CONSTRUCTOR

=head2 new

  my $buffer = TDrawBuffer->new();

Creates a new, empty draw buffer with a width equal to the maximum view width.

=head1 METHODS

=head2 moveBuf

  $buffer->moveBuf($indent, \@source, $attr, $count);

Copies a sequence of characters from the source buffer into the draw buffer,
starting at the specified position and applying the given attribute.

=head2 moveCStr

  $buffer->moveCStr($indent, $string, $attrs);

Writes a string containing Turbo Vision style tilde markers into the buffer,
applying the specified attributes.

=head2 moveChar

  $buffer->moveChar($indent, $char, $attr, $count);

Writes a repeated character into the buffer using the given attribute.

=head2 moveStr

  $buffer->moveStr($indent, $string, $attrs);

Writes a plain string into the buffer starting at the specified position and
applies the given attributes.

=head2 putAttribute

  $buffer->putAttribute($index, $attr);

Sets the display attribute at the specified buffer position.

=head2 putChar

  $buffer->putChar($index, $char);

Sets the character value at the specified buffer position.

=head1 SEE ALSO

L<TUI::Views::View>,
L<TUI::Views::Window>

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
