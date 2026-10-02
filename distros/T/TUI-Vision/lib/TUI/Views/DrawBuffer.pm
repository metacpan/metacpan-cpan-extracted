package TUI::Views::DrawBuffer;
# ABSTRACT: TDrawBuffer stores a line of text for output in views

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDrawBuffer
  new_TDrawBuffer
);

use List::Util qw( min max );
use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw(
  :is
  :types
  Maybe
);

use TUI::Drivers::AttrPair;
use TUI::Drivers::ColorAttr;
use TUI::Drivers::Screen;
use TUI::Drivers::ScreenCell;
use TUI::Views::Const qw( maxViewWidth );

sub TDrawBuffer() { __PACKAGE__ }
sub new_TDrawBuffer { __PACKAGE__->from(@_) }

# import global variables
use vars qw(
  $screenHeight
  $screenWidth
);
{
  no strict 'refs';
  *screenHeight = \${ TScreen . '::screenHeight' };
  *screenWidth  = \${ TScreen . '::screenWidth' };
}

my $getBufferLength = sub {    # $num ()
	assert ( @_ == 0 );
	return max(
		8 + max( $screenWidth, $screenHeight ),
		maxViewWidth,
	);
};

# macro for coercing a value into a TColorAttr object
my $coerceAttr = sub {
  return ref $_[0] ? $_[0] : TColorAttr->new( bios => $_[0] );
};

# macro for coercing a value into a TAttrPair object
my $coerceAttrPair = sub {
  return ref $_[0] ? $_[0] : TAttrPair->new( bios => $_[0] );
};

sub new {    # $obj ()
  state $sig = signature(
    method => 1,
    pos    => [],
  );
  my ( $class ) = $sig->( @_ );
  return bless [], $class;
}

sub from {    # $obj ()
  goto &new;
}

sub putAttribute {    # void ($indent, $attr)
  state $sig = signature(
    method => Object,
    pos    => [
      PositiveOrZeroInt, 
      sub { is_Object $_[0] or is_PositiveOrZeroInt $_[0] }, 
    ],
  );
  my ( $self, $indent, $attr ) = $sig->( @_ );
  assert ( $indent < &$getBufferLength() );
  my $cell = $self->[$indent] //= TScreenCell->new();
  $cell->attribute( $attr );
  return;
}

sub putChar {    # void ($indent, $ch)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Str],
  );
  my ( $self, $indent, $ch ) = $sig->( @_ );
  assert ( length $ch );
  assert ( $indent < &$getBufferLength() );
  my $cell = $self->[$indent] //= TScreenCell->new();
  $cell->character( $ch );
  return;
}

sub moveBuf {    # void ($indent, \@source, $attr|undef, $count)
  state $sig = signature(
    method => Object,
    pos    => [
      PositiveOrZeroInt, 
      ArrayLike, 
      sub { !defined $_[0] or is_Object $_[0] or is_PositiveOrZeroInt $_[0] }, 
      PositiveOrZeroInt,
    ],
  );
  my ( $self, $indent, $source, $attr, $count ) = $sig->( @_ );
  assert ( $indent + $count <= &$getBufferLength() );

  if ( defined $attr ) {
    $attr = $attr->$coerceAttr();
    for ( my $i = 0 ; $i < $count ; $i++ ) {
      my $c = $source->[$i]; 
      my $cell = $self->[ $indent + $i ] //= TScreenCell->new();
      $cell->character( ref $c ? $c->character() : chr( $c ) );
      $cell->attribute( $attr );
    }
  }
  else {
    for ( my $i = 0 ; $i < $count ; $i++ ) {
      my $c = $source->[$i];
      my $cell = $self->[ $indent + $i ] //= TScreenCell->new();
      if ( ref $c ) {
        $cell->assign( $c );
      }
      else {
        my ( $ch, $cellAttr ) = unpack 'aC' => pack 'v' => $c;
        $cell->character( $ch );
        $cell->attribute( $cellAttr );
      }
    }
  }
  return;
} #/ sub moveBuf

sub moveChar {    # void ($indent, $c|undef, $attr|undef, $count)
  state $sig = signature(
    method => Object,
    pos    => [
      PositiveOrZeroInt, 
      Maybe[Str], 
      sub { !defined $_[0] or is_Object $_[0] or is_PositiveOrZeroInt $_[0] }, 
      PositiveOrZeroInt,
    ],
  );
  my ( $self, $indent, $c, $attr, $count ) = $sig->( @_ );
  assert ( $indent + $count <= &$getBufferLength() );

  my $dest = $indent;
  if ( defined $attr ) {
    $attr = $attr->$coerceAttr();    # only for performance
    if ( defined $c ) {
      for ( 1 .. $count ) {
        my $cell = $self->[$dest++] //= TScreenCell->new();
        $cell->character( $c );
        $cell->attribute( $attr );
      }
    }
    else {
      for ( 1 .. $count ) {
        my $cell = $self->[$dest++] //= TScreenCell->new();
        $cell->attribute( $attr );
      }
    }
  }
  else {
    assert ( length $c );
    for ( 1 .. $count ) {
      my $cell = $self->[$dest++] //= TScreenCell->new();
      $cell->character( $c );
    }
  }
  return;
} #/ sub moveChar

sub moveCStr {    # $num ($indent, $str, $attrs)
  state $sig = signature(
    method => Object,
    pos    => [
      PositiveOrZeroInt, 
      Str, 
      sub { is_ArrayLike $_[0] or is_PositiveOrZeroInt $_[0] }, 
    ],
  );
  my ( $self, $indent, $str, $attrs ) = $sig->( @_ );

  my $dest   = $indent;
  my $toggle = 1;
  $attrs = $attrs->$coerceAttrPair();
  my $curAttr = $attrs->[0];

  foreach my $ch ( split //, $str ) {
    if ( $ch eq '~' ) {
      $curAttr = $attrs->[$toggle];
      $toggle  = 1 - $toggle;
    }
    else {
      my $cell = $self->[$dest++] //= TScreenCell->new();
      $cell->character( $ch );
      $cell->attribute( $curAttr );
    }
  }
  return $dest - $indent;
} #/ sub moveCStr

sub moveStr {    # $num ($indent, $str, $attr|undef)
  state $sig = signature(
    method => Object,
    pos    => [
      PositiveOrZeroInt, 
      Str, 
      sub { !defined $_[0] or is_Object $_[0] or is_PositiveOrZeroInt $_[0] }, 
    ],
  );
  my ( $self, $indent, $str, $attr ) = $sig->( @_ );

  my @chars = split //, $str;
  assert ( $indent + @chars <= &$getBufferLength() );

  my $dest = $indent;
  if ( defined $attr ) {
    $attr = $attr->$coerceAttr();
    for my $ch ( @chars ) {
      my $cell = $self->[$dest++] //= TScreenCell->new();
      $cell->character( $ch );
      $cell->attribute( $attr );
    }
  }
  else {
    for my $ch ( @chars ) {
      my $cell = $self->[$dest++] //= TScreenCell->new();
      $cell->character( $ch );
    }
  }
  return scalar @chars;
}

sub dump {    # $str (|$maxLength)
  state $sig = signature(
    method => Object,
    pos    => [
      PositiveOrZeroInt, { default => 5 },
    ],
  );
  my ( $self, $maxLength ) = $sig->( @_ );

	$maxLength = max( $maxLength, &$getBufferLength() );
  my @cells;
  for my $i ( 0 .. $maxLength - 1 ) {
    my $cell = $self->[$i] //= TScreenCell->new();
    push @cells, sprintf(
      '%d:%s',
      $cell->attribute()->toBIOS(),
      $cell->character()->getText(),
    );
  }

  no warnings 'once';
  require Data::Dumper;
  my $str = Data::Dumper::Dumper( \@cells );
  $str =~ s/(^|\s)\$VAR\d+\b/$1'$self'/g;
  return $str;
}

1

__END__

=pod

=head1 NAME

TUI::Views::DrawBuffer - temporary line buffer for screen output

=head1 SYNOPSIS

  use TUI::Views;

  my $buffer = TDrawBuffer->new();

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

This type is a lightweight value type and is not derived from 
L<TObject|TUI::Objects::Object>. Internally, it corresponds to an array of 
fixed width, where each element combines a character and its visual attributes.

C<TDrawBuffer> is primarily used inside L<TView|TUI::Views::View> drawing 
routines. Text and attributes are written into the buffer using helper methods, 
and the buffer is then passed to L<TView|TUI::Views::View> methods such as 
L</writeLine> or L</writeBuf> to render the output on screen.

=head1 CONSTRUCTOR

=head2 new

  my $buffer = TDrawBuffer->new();

Creates a new, empty draw buffer with a width equal to the maximum view width.

=head1 METHODS

=head2 moveBuf

  $buffer->moveBuf($indent, \@source, $attr | undef, $count);

Copies character data from C<@source> into the draw buffer.

Source elements may be Unicode codepoints, legacy packed screen-cell
values (C<short>), or L<TScreenCell|TUI::Drivers::ScreenCell> objects.

If C<$attr> is defined, it overrides any attribute information present
in the source data.

Otherwise, attribute information is taken from the source element when
available (either from a legacy packed screen-cell value or from a
L<TScreenCell|TUI::Drivers::ScreenCell> object).

=head2 moveChar

  $buffer->moveChar($indent, $char | undef, $attr | undef, $count);

Writes a repeated character (C<undef> to retain the already present characters) 
into the buffer using the given attribute (C<undef> to retain the already 
present attributes).

B<Note:> If both C<$char> and C<$attr> are C<undef>, the attributes are 
retained but the characters are not.

=head2 moveCStr

  my $num = $buffer->moveCStr($indent, $string, $attrs);

Writes a string containing I<Turbo Vision> style tilde markers into the buffer,
applying the specified attributes.

Returns the number of cells in the buffer that were actually updated.

=head2 moveStr

  my $num = $buffer->moveStr($indent, $string, $attr | undef);

Writes a plain string into the buffer starting at the specified position and
applies the given attributes.

Returns the number of cells in the buffer that were actually updated.

=head2 putAttribute

  $buffer->putAttribute($index, $attr);

Sets the display attribute at the specified buffer position.

=head2 putChar

  $buffer->putChar($index, $char);

Sets the character value at the specified buffer position.

=head1 SEE ALSO

L<TView|TUI::Views::View>,
L<TWindow|TUI::Views::Window>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2019-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution).

=cut
