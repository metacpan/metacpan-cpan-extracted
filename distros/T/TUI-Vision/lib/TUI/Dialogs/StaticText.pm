package TUI::Dialogs::StaticText;
# ABSTRACT: Displays fixed text inside a dialog

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStaticText
  new_TStaticText
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Dialogs::Const qw( cpStaticText );
use TUI::Views::Const qw( gfFixed );
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;

sub TStaticText() { __PACKAGE__ }
sub name() { 'TStaticText' }
sub new_TStaticText { __PACKAGE__->from(@_) }

extends TView;

# protected attributes
has text => ( is => 'ro', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds => Object,
      text   => Str, { alias => 'aText' },
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
  $self->{growMode} |= gfFixed;
  return;
}

sub from {    # $obj ($bounds, $aText)
  state $sig = signature(
    method => 1,
    pos    => [Object, Str],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], text => $args[1] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{text} = undef;
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $color;
  my $center;
  my ( $i, $j, $l, $p, $y );
  my $b = TDrawBuffer->new();
  my $s;

  $color = $self->getColor( 1 );
  $self->getText( \$s );
  $l      = length( $s );
  $p      = 0;
  $y      = 0;
  $center = false;
  while ( $y < $self->{size}{y} ) {
    $b->moveChar( 0, ' ', $color, $self->{size}{x} );
    if ( $p < $l ) {
      if ( substr( $s, $p, 1 ) eq "\003" ) {
        $center = 1;
        ++$p;
      }
      $i = $p;
      do {
        $j = $p;
        while ( $p < $l && substr( $s, $p, 1 ) eq ' ' ) {
          ++$p;
        }
        while ( $p < $l
          && substr( $s, $p, 1 ) ne ' '
          && substr( $s, $p, 1 ) ne "\n" )
        {
          ++$p;
        }
        } while ( $p < $l
          && $p < $i + $self->{size}{x} 
          && substr( $s, $p, 1 ) ne "\n"
        );
      if ( $p > $i + $self->{size}{x} ) {
        if ( $j > $i ) {
          $p = $j;
        }
        else {
          $p = $i + $self->{size}{x};
        }
      }
      if ( $center ) {
        $j = int( ( $self->{size}{x} - $p + $i ) / 2 );
      }
      else {
        $j = 0;
      }
      $b->moveStr( $j, substr( $s, $i, $p - $i ), $color );
      while ( $p < $l && substr( $s, $p, 1 ) eq ' ' ) {
        ++$p;
      }
      if ( $p < $l && substr( $s, $p, 1 ) eq "\n" ) {
        $center = 0;
        ++$p;
      }
    } #/ if ( $p < $l )
    $self->writeLine( 0, $y++, $self->{size}{x}, 1, $b );
  } #/ while ( $y < $self->{size...})
  return;
} #/ sub draw

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpStaticText, 
    size => length( cpStaticText ),
  );
  return $palette->clone();
}

sub getText {    # void (\$s)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef],
  );
  my ( $self, $s ) = $sig->( @_ );
  if ( !$self->{text} ) {
    $$s = '';
  }
  else {
    $$s = substr( $self->{text}, 0, 255 );
  }
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Dialogs::StaticText - displays fixed text inside a dialog

=head1 HIERARCHY

  TObject
    TView
      TStaticText

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Dialogs;

  my $source = 'input.txt';
  my $dest   = 'output.txt';
  my $bounds = TRect->new( ax => 1, ay => 2, bx => 58, by => 5 );

  my $static = TStaticText->new(
    bounds => $bounds,
    text   => "\003$source to $dest",
  );

  $dialog->insert($static);

=head1 DESCRIPTION

C<TStaticText> implements a simple, non-editable text display view used mainly
inside dialogs and windows. It renders a fixed text string within a rectangular
area and does not accept user input.

The control supports both single-line and multi-line text. If the bounding
rectangle spans multiple rows, the text is automatically wrapped to fit the
available space. Explicit line breaks may also be embedded in the text.

Special formatting markers are supported for compatibility with classic Turbo
Vision behavior. For example, a leading centering marker causes the text to be
centered horizontally within its bounds.

C<TStaticText> is typically used for labels, messages, and explanatory text.
Related views include C<TLabel> and C<TParamText>.

=head2 Commonly Used Features

Most code only instantiates C<TStaticText> with C<new> (or C<new_TStaticText>)
and inserts it into a dialog. After initialization, it usually remains a
passive display element; direct method calls are uncommon outside framework
internals.

=head1 ATTRIBUTES

=over

=item text

Text string displayed by the static text view (I<Str>).

=back

=head1 CONSTRUCTOR

=head2 new

  my $static = TStaticText->new(
    bounds => $bounds,
    text   => $text
  );

Creates a new static text view.

=over

=item bounds

Bounding rectangle of the view (I<TRect>).

=item text

Text to be displayed (I<Str>).

=back

=head2 new_TStaticText

  my $static = new_TStaticText($bounds, $text);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 DESTRUCTOR

=head2 DEMOLISH

  $self->DEMOLISH($in_global_destruction);

Destroys the static text view and releases associated resources. This method
corresponds to the Turbo Vision destructor and is normally invoked
automatically by the owning group.

=head1 METHODS

=head2 draw

  $static->draw();

Draws the text into the view, applying wrapping and alignment rules.

=head2 getPalette

  my $palette = $static->getPalette();

Returns the color palette used to draw the static text.

=head2 getText

  $static->getText(\$string);

Copies the internal text string into the supplied scalar.

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
