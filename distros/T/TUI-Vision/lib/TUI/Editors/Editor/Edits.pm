package TUI::Editors::Editor::Edits;
# ABSTRACT: TEditor buffer and line functions (1:1 port)

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use PerlX::Assert::PP;
use Terminal::WCWidth qw( wcwidth );
use TUI::toolkit::Types qw( :is );

sub TUI::Editors::Editor::bufChar {    # $char ($self, $P)
  my ( $self, $P ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $P );
  return substr( $self->{buffer}, $P, 1 );
}

sub TUI::Editors::Editor::bufPtr {    # $pos ($self, $P)
  my ( $self, $P ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $P );
  return $P;
}

sub TUI::Editors::Editor::formatLine {    # void ($self, $b, $linePtr, $width, $colors)
  my ( $self, $b, $linePtr, $width, $colors ) = @_;
  assert ( @_ == 5 );
  assert ( is_Object $self );
  assert ( is_Object $b );
  assert ( is_PositiveOrZeroInt $linePtr );
  assert ( is_Int $width );
  assert ( is_PositiveInt $colors );

  my $P        = $linePtr;
  my $selStart = $self->{selStart};
  my $selEnd   = $self->{selEnd};
  my $cNorm    = $colors & 0xFF;
  my $cSel     = $colors >> 8;

  my $eol = $self->lineEnd( $P );
  my $x   = 0;

  while ( $P < $eol ) {
    my $ch = $self->bufChar( $P );
    my $color = ( $selStart <= $P && $P < $selEnd ) ? $cSel : $cNorm;

    if ( $ch eq "\t" ) {
      last if $x >= $width;

      my $next = ( $x | 7 ) + 1;
      $next = $width if $next > $width;
      $b->moveChar( $x, ' ', $color, $next - $x );
      $x = $next;
    }
    else {
      my $w = wcwidth( ord $ch );
      $w = 1 if $w < 0;

      last if $x > $width;
      last if $x == $width && $w > 0;
      last if $x + $w > $width;

      $b->moveStr( $x, $ch, $color );
      $x += $w;
    }

    ++$P;
  }

  if ( $x < $width ) {
    my $color = $selStart <= $P && $P < $selEnd ? $cSel : $cNorm;
    $b->moveChar( $x, ' ', $color, $width - $x );
  }

  return;
}

sub TUI::Editors::Editor::lineEnd {    # $pos ($self, $p)
  my ( $self, $p ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $p );

  my $len = $self->bufLen;
  return $len
    if $p >= $len;

  pos( $self->{buffer} ) = $p;
  $self->{buffer} =~ /\G(?:(?!\R).)*+/gcs;

  return pos( $self->{buffer} );
}

sub TUI::Editors::Editor::lineStart {    # $pos ($self, $p)
  my ( $self, $p ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $p );

  state $chunkSize = 256;

  return 0 
    if $p <= 0;

  my $end = $p;
  while ( $end > 0 ) {
    my $start = $end - $chunkSize;
    $start = 0 if $start < 0;
    my $chunk = substr( $self->{buffer}, $start, $end - $start );
    return $start + $+[0] 
      if $chunk =~ /.*\R/gs;
    $end = $start;
  }

  return 0;
}

sub TUI::Editors::Editor::nextChar {    # $pos ($self, $p)
  my ( $self, $p ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $p );

  my $len = $self->bufLen;
  return $len 
    if $p >= $len;

  pos( $self->{buffer} ) = $p;
  return pos( $self->{buffer} )
    if $self->{buffer} =~ /\G\R/gc;

  return $p + 1;
}

sub TUI::Editors::Editor::nextLine {    # $pos ($self, $p)
  my ( $self, $p ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $p );
  return $self->nextChar( $self->lineEnd( $p ) );
}

sub TUI::Editors::Editor::prevChar {    # $pos ($self, $p)
  my ( $self, $p ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $p );

  return 0
    if $p <= 0;

  if ( $p >= 2 ) {
    pos( $self->{buffer} ) = $p - 2;
    return $p - 2
      if $self->{buffer} =~ /\G\R/gc
      && pos( $self->{buffer} ) == $p;
  }

  return $p - 1;
}

sub TUI::Editors::Editor::prevLine {    # $pos ($self, $p)
  my ( $self, $p ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $p );
  return $self->lineStart( $self->prevChar( $p ) );
}

1

__END__

=pod

=head1 NAME

TUI::Editors::Editor::Edits - TEditor buffer and line functions

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Editors;

  my $editor = new_TEditor(
    TRect->new( ax => 0, ay => 0, bx => 80, by => 24 ),
    undef,
    undef,
    undef,
    1024,
  );

  my $start = $editor->lineStart( $pos );
  my $char  = $editor->bufChar( $pos );

=head1 DESCRIPTION

C<TUI::Editors::Editor::Edits> implements the low-level buffer, line
navigation, formatting, and character movement operations used by
L<TEditor|TUI::Editors::Editor>.

The implementation preserves the original Turbo Vision editor API while using
native Perl string operations. Buffer positions refer to characters in the
logical editor buffer rather than encoded byte offsets, allowing decoded
Unicode strings to be handled directly.

Line endings follow Perl's C<\R> semantics. A complete line-ending sequence is
treated as one logical unit where appropriate.

=head1 METHODS

=head2 bufChar

  my $char = $editor->bufChar( $pos );

Returns the character at logical buffer position C<$pos>.

The returned value is a Perl character string. For decoded Unicode strings,
C<$pos> therefore identifies a character position rather than a UTF-8 byte
offset.

=head2 bufPtr

  my $physical = $editor->bufPtr( $pos );

Returns the physical buffer position corresponding to logical buffer position
C<$pos>.

This method preserves the original Turbo Vision abstraction between logical
and physical buffer positions. In a contiguous buffer, logical and physical
positions may be identical.

=head2 formatLine

  $editor->formatLine( $buffer, $linePtr, $width, $colors );

Formats one editor line into C<$buffer>, a C<TDrawBuffer>.

C<$linePtr> specifies the logical position at which the line begins.
C<$width> specifies the number of screen cells to format. C<$colors> contains
the normal and selected text attributes, following the Turbo Vision
C<TAttrPair> convention.

Characters inside the current selection use the selected attribute; all other
characters use the normal attribute.

Tab characters advance to the next eight-column tab stop. Unicode character
width is determined using C<wcwidth>. Combining characters occupy no
additional screen cells and may be appended to a character in the final
formatted cell. Wide characters occupy their corresponding number of terminal
cells.

Control characters which are not line endings occupy one screen cell.

Formatting stops at the logical end of the line or when the requested width
has been filled. Remaining cells are filled with spaces using the attribute
active at the final logical buffer position.

=head2 lineEnd

  my $end = $editor->lineEnd( $pos );

Returns the logical position of the line ending at or after C<$pos>.

The returned position identifies the beginning of the line-ending sequence and
does not include it. If no line ending follows C<$pos>, the logical buffer
length is returned.

Line endings are recognized using Perl's C<\R> semantics.

=head2 lineStart

  my $start = $editor->lineStart( $pos );

Returns the logical position at which the line containing C<$pos> begins.

The result is the position immediately following the preceding line-ending
sequence. Zero is returned when there is no preceding line ending.

Line endings are recognized using Perl's C<\R> semantics.

=head2 nextChar

  my $next = $editor->nextChar( $pos );

Returns the logical position following the character at C<$pos>.

When C<$pos> points to the beginning of a multi-character line-ending
sequence, the complete sequence is treated as one logical unit. Otherwise the
position advances by one Perl character.

If C<$pos> is at or beyond the logical end of the buffer, the buffer length is
returned.

=head2 nextLine

  my $next = $editor->nextLine( $pos );

Returns the logical position at which the next line begins.

The method finds the end of the current line and advances over its complete
line-ending sequence. If there is no following line, the logical end of the
buffer is returned.

=head2 prevChar

  my $previous = $editor->prevChar( $pos );

Returns the logical position preceding C<$pos>.

A multi-character line-ending sequence ending at C<$pos> is treated as one
logical unit. Otherwise the position moves backwards by one Perl character.

Zero is returned when C<$pos> is at the beginning of the buffer.

=head2 prevLine

  my $previous = $editor->prevLine( $pos );

Returns the logical position at which the preceding line begins.

The method moves to the preceding logical character and then locates the
beginning of the line containing that character. Zero is returned when there
is no preceding line.

=head1 SEE ALSO

L<TEditor|TUI::Editors::Editor>

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
