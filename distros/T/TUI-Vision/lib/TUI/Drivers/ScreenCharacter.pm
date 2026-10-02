package TUI::Drivers::ScreenCharacter;
# ABSTRACT: character value type for screen cells

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TScreenCharacter
);

require bytes;
use PerlX::Assert::PP;
use Scalar::Util qw( blessed );
use Terminal::WCWidth qw( wcswidth );

sub TScreenCharacter() { __PACKAGE__ }

sub new {    # $cch (|%args)
  my ( $class, @args ) = @_;
  assert ( $class and !ref $class );

  # TScreenCharacter->new()
  my $text;
  if ( !@args ) {
    $text = '';    # Watch out! This is a trivial constructor.
  }

  # TScreenCharacter->new( text => Str )
  elsif ( @args == 2 && $args[0] eq 'text' ) {
    $text = $args[1];
    assert ( !ref $text and length $text );
  }

  else {
    return;
  }

  return bless \$text, $class;
}

sub assign {    # void ($other)
  my ( $self, $other ) = @_;
  assert ( blessed $self );
  assert ( blessed $other );
  $$self = $$other;
  return;
}

sub clone {    # $cch ()
  my ( $self ) = @_;
  assert ( blessed $self );
  my $v = $$self;
  return bless \$v, ref $self;
}

sub isWide {    # $bool ()
  assert ( blessed $_[0] );
  my $text = ${ $_[0] };
  return !!0
    if bytes::length( $text ) <= 1;
  return wcswidth( ${ $_[0] } ) >= 2;
}

sub isWideCharTrail {    # $bool ()
  assert ( blessed $_[0] );
  return ${ $_[0] } eq "\0";
}

sub appendZeroWidthChar {    # void ($mbc)
  my ( $self, $mbc ) = @_;
  assert ( blessed $self );
  assert ( !ref $mbc );
  ${$self} .= $mbc;
  return;
}

sub getText {    # $ch ()
  assert ( blessed $_[0] );
  my $text = ${ $_[0] };
  return length( $text ) ? $text : "\0";
}

1;

__END__

=head1 NAME

TUI::Drivers::ScreenCharacter - character value type for screen cells

=head1 SYNOPSIS

  use TUI::Drivers;

  my $ch = TScreenCharacter->new(
    text => 'A',
  );

  my $text = $ch->getText;

=head1 DESCRIPTION

C<TScreenCharacter> represents the text stored in a single screen cell.

A cell may contain:

=over

=item *

A single-byte ASCII or extended ASCII character.

=item *

A UTF-8 character or character sequence occupying one or two screen columns.

=item *

A special wide-character trail marker representing the trailing cell of a wide
character.

=back

The stored text always contains a visible character, unless the value
represents a wide-character trail marker. Zero-width Unicode characters may
therefore only appear as part of a character sequence attached to a visible
base character.

Wide-character trail markers are internal placeholders used to represent the
additional screen cell occupied by a wide character. They do not contribute
visible text of their own.

Applications may construct and manipulate C<TScreenCharacter> values directly, but
screen text is usually written through the functions provided by
L<TText|TUI::Drivers::Text>.

=head1 CONSTRUCTOR

=head2 new

Creates a new character value.

Construct an empty value:

  my $ch = TScreenCharacter->new();

Construct from text:

  my $ch = TScreenCharacter->new(
    text => 'A',
  );

Construct a wide-character trail placeholder:

  my $trail = TScreenCharacter->new(
    text => "\0",
  );

=head1 METHODS

=head2 appendZeroWidthChar

  $self->appendZeroWidthChar($text);

Appends a zero-width Unicode character sequence to the stored text.

The resulting value continues to represent a single screen cell and must still 
contain at least one visible character.

=head2 assign

  $self->assign($other);

Copies the contents of another C<TScreenCharacter> into the current one.

=head2 clone

  my $cch = $self->clone();

Returns a new C<TScreenCharacter> object that is a copy of the current one.

=head2 getText

 my $ch = $self->getText();

Returns the stored text.

=head2 isWide

 my $bool = $self->isWide();

Returns true if the stored text does not occupy exactly one screen column.

=head2 isWideCharTrail

 my $bool = $self->isWideCharTrail();

Returns true if the value represents a wide-character trail placeholder.

=head1 SEE ALSO

L<TScreenCell|TUI::Drivers::ScreenCell>,
L<TColorAttr|TUI::Drivers::ColorAttr>

=head1 AUTHORS

=over

=item * magiblot <magiblot@hotmail.com> (original cell char design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2026 the L</AUTHORS> listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
