package TUI::Editors::Util;
# ABSTRACT: Utility functions for editor buffers

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  countLines
  iScan
  scan
);
our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

use TUI::toolkit qw( signature );
use TUI::toolkit::Types qw(
  Maybe
  PositiveOrZeroInt
  Str
);

use TUI::Editors::Const qw( sfSearchFailed );

sub countLines {    # $count ($buf, |$count)
  state $sig = signature(
    pos => [
      Str,
      PositiveOrZeroInt, { optional => 1 },
    ],
  );
  my ( $buf, $count ) = $sig->( @_ );

  return 0 unless length $buf;

  $buf = substr( $buf, 0, $count )
    if defined $count && $count < length $buf;

  my $lines = () = $buf =~ /\R/g;
  return $lines;
}

sub iScan {    # $pos ($block, $size, $str)
  state $sig = signature(
    pos => [
      Str,
      PositiveOrZeroInt,
      Str,
    ],
  );
  my ( $block, $size, $str ) = $sig->( @_ );

  return sfSearchFailed unless length $str;

  $block = substr( $block, 0, $size )
    if $size < length $block;

  return $-[0] if $block =~ /\Q$str\E/i;
  return sfSearchFailed;
}

sub scan {    # $pos ($block, $size, $str)
  state $sig = signature(
    pos => [
      Str,
      PositiveOrZeroInt,
      Str,
    ],
  );
  my ( $block, $size, $str ) = $sig->( @_ );

  return sfSearchFailed unless length $str;

  $block = substr( $block, 0, $size )
    if $size < length $block;

  my $pos = index( $block, $str );
  return $pos >= 0 ? $pos : sfSearchFailed;
}

1

__END__

=pod

=head1 NAME

TUI::Editors::Util - Utility functions for editor buffers

=head1 SYNOPSIS

  use TUI::Editors;

  # The umbrella module does not re-export these functions.
  my $buffer = "first\nsecond\n";
  my $lines  = TUI::Editors::Util::countLines($buffer);
  my $ipos   = TUI::Editors::Util::iScan($buffer, length $buffer, 'second');

=head1 DESCRIPTION

C<TUI::Editors::Util> provides low-level line-counting and search functions
used by L<TEditor|TUI::Editors::Editor>.

The functions preserve the buffer-and-length calling convention of the
original I<Turbo Vision> editor utilities while using native Perl strings.
Positions and lengths refer to Perl characters rather than encoded byte
offsets.

All functions are available for explicit import. Nothing is exported by
default. The C<:all> tag imports all functions.

=head1 FUNCTIONS

=head2 countLines

  my $lines = countLines($buffer);
  my $lines = countLines($buffer, $count);

Counts the line-ending sequences in C<$buffer>.

When C<$count> is supplied, only the first C<$count> Perl characters are
examined. When C<$count> is omitted or is greater than the available length,
the complete buffer is examined.

An empty buffer contains no line endings and returns zero.

Line endings follow Perl's C<\R> semantics. A CR LF pair therefore counts as
one line ending.

The function corresponds to the original Turbo Vision C<countLines> utility,
whose arguments are a buffer address and a character count.

=head2 iScan

  my $pos = iScan($block, $size, $string);

Searches for the first case-insensitive occurrence of C<$string> within the
first C<$size> Perl characters of C<$block>.

The search string is treated as literal text rather than as a regular
expression. Matching uses Perl's case-insensitive Unicode rules when the
arguments contain decoded Unicode strings.

The returned position is relative to the beginning of C<$block>.

C<sfSearchFailed> is returned when C<$string> is empty or no match is found.

=head2 scan

  my $pos = scan($block, $size, $string);

Searches for the first exact occurrence of C<$string> within the first
C<$size> Perl characters of C<$block>.

The comparison is case-sensitive. The returned position is relative to the
beginning of C<$block>.

C<sfSearchFailed> is returned when C<$string> is empty or no match is found.

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
