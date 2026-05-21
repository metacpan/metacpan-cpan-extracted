package TUI::App::Background;
# ABSTRACT: TBackground forms the background for the applications.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TBackground
  new_TBackground
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  :Object
  Str
);

use TUI::App::Const qw( cpBackground );
use TUI::Views::Const qw( :gfXXXX );
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;

sub TBackground() { __PACKAGE__ }
sub new_TBackground { __PACKAGE__->from(@_) }

extends TView;

# protected attributes
has pattern => ( is => 'ro', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds  => Object,
      pattern => Str, { alias => 'aPattern' }
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
  $self->{growMode} = gfGrowHiX | gfGrowHiY;
  return;
}

sub from {    # $obj ($bounds, $aPattern)
  state $sig = signature(
    method => 1,
    pos    => [Object, Str],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], pattern => $args[1] );
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $b = TDrawBuffer->new();

  $b->moveChar( 0, $self->{pattern}, $self->getColor(0x01), $self->{size}{x} );
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpBackground, 
    size => length( cpBackground )
  );
  return $palette->clone();
}

1

__END__

=pod

=head1 NAME

TUI::App::Background - forms the background for the applications

=head1 HIERARCHY

  TObject
    TView
      TBackground

=head1 SYNOPSIS

  use TUI::App;

  my $bg = TBackground->new(
    bounds  => $bounds,
    pattern => chr(0xFF)
  );

=head1 DESCRIPTION

C<TBackground> represents the background view that forms the visual backdrop of
a TUI::Vision application. It fills its bounding rectangle by repeatedly
drawing a single character pattern.

Background views are typically created and managed automatically by the
desktop. Applications rarely need to interact with C<TBackground> directly
unless a custom background is desired.

=head2 Commonly Used Features

Most programs use C<TBackground> indirectly through C<TDeskTop>; the default
desktop creation path already instantiates a background object with the global
desktop pattern. Direct usage is uncommon and usually limited to customizing
appearance by overriding C<TDeskTop::initBackground()> and returning a
background with a different C<pattern> character.

For custom backgrounds, the typical workflow is: derive a desktop class,
override C<initBackground()> to create 
C<<TBackground->new(bounds => ..., pattern => ... )>>, then return that desktop 
from the application's C<initDeskTop()> override.

=head1 CONSTRUCTOR

=head2 new

  my $background = TBackground->new(
    bounds  => $bounds,
    pattern => $pattern
  );

Creates a new background view.

=over

=item bounds

Bounding rectangle defining the area covered by the background (I<TRect>).

=item pattern

Single-character string used as the background pattern (I<Str>).

=back

=head1 ATTRIBUTES

The following attributes are managed internally and exposed as read-only
accessors.

=over

=item pattern

The character pattern replicated to fill the background (I<Str>).

=back

=head1 METHODS

=head2 draw

  $background->draw();

Draws the background pattern across the view area.

=head2 getPalette

  my $palette = $background->getPalette();

Returns the color palette used to draw the background.

=head1 EXAMPLE

The following example demonstrates how to override the desktop background by
providing a custom C<TBackground> implementation.

  package TSampleProgram;
  use parent 'TApplication';

  package TNewDeskTop;
  use parent 'TDeskTop';

  sub TNewDeskTop::initBackground {
    my ($self, $bounds) = @_;

    return TBackground->new(
      bounds  => $bounds,
      pattern => chr(0xFF)
    );
  }

  sub TSampleProgram::initDeskTop {
    my ($self, $bounds) = @_;

    $bounds->{a}{y}++;
    $bounds->{b}{y}--;

    return TNewDeskTop->new(bounds => $bounds);
  }

  package main;

  my $app = TSampleProgram->new;
  $app->run;

=head1 SEE ALSO

L<TUI::App::DeskTop>,
L<TUI::Views::View>,
L<TUI::Objects::Rect>

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
