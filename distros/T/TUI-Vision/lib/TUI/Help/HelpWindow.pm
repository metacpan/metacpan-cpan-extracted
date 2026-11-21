package TUI::Help::HelpWindow;
# ABSTRACT: window that hosts a help topic viewer

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THelpWindow
  new_THelpWindow
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw(
  :is
  :types
);

use TUI::Help::Const qw( cHelpWindow );
use TUI::Help::HelpFile;
use TUI::Help::HelpViewer;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  ofCentered
  sbHandleKeyboard
  sbHorizontal
  sbVertical
  wnNoNumber
);
use TUI::Views::Palette;
use TUI::Views::Window;

sub THelpWindow() { __PACKAGE__ }
sub name() { 'THelpWindow' }
sub new_THelpWindow { __PACKAGE__->from(@_) }

extends TWindow;

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      hFile   => Object,              { alias => 'aHelpFile' },
      context => PositiveOrZeroInt,
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = TWindow->BUILDARGS(
    bounds => TRect->new( ax => 0, ay => 0, bx => 50, by => 18 ),
    title  => 'Help',
    number => wnNoNumber,
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashRef $args );
  $self->{options} |= ofCentered;
  my $r = $self->getExtent();
  $r->grow( -2, -1 );
  $self->insert( THelpViewer->new(
    bounds     => $r,
    hScrollBar => $self->standardScrollBar( sbHorizontal | sbHandleKeyboard ),
    vScrollBar => $self->standardScrollBar( sbVertical | sbHandleKeyboard ),
    hFile      => $args->{hFile},
    context    => $args->{context},
  ) );
  return;
}

sub from {    # $obj ($aHelpFile, $context)
  state $sig = signature(
    method => 1,
    pos    => [Object, PositiveOrZeroInt],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( hFile => $args[0], context => $args[1] );
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cHelpWindow,
    size => length( cHelpWindow ),
  );
  return $palette->clone();
}

1

__END__

=pod

=head1 NAME

TUI::Help::HelpWindow - window that hosts a help topic viewer

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow
          THelpWindow

=head1 SYNOPSIS

  use TUI::Help;

  open my $stream, '<:raw', 'help.hlp' or die $!;
  my $helpFile = new_THelpFile( $stream );

  $desktop->insert( new_THelpWindow( $helpFile, 10 ) );

=head1 DESCRIPTION

C<THelpWindow> is the Perl port of the Turbo Vision C<THelpWindow>. It is the
window that presents online help. The window has a fixed size of 50 columns by
18 rows, carries the title C<Help>, and is created without a window number
(C<wnNoNumber>). It also sets the C<ofCentered> option.

When the window is constructed, it inserts a
L<THelpViewer|TUI::Help::HelpViewer> into its interior. The viewer is inset by
two columns on the left and right and by one row at the top and bottom. It has
a horizontal and a vertical standard scroll bar, both of which handle keyboard
input. The viewer shows the help topic that belongs to the context number
passed to the constructor. Topics are read from the
L<THelpFile|TUI::Help::HelpFile> object passed as C<hFile>.

=head1 CONSTRUCTOR

=head2 new

  my $window = THelpWindow->new(
    hFile   => $helpFile,
    context => $context,
  );

Creates a help window that displays the topic for the help context C<context>
of the help file C<hFile>.

=over

=item hFile

The help source, a L<THelpFile|TUI::Help::HelpFile> object.

=item context

The non-negative help context number of the topic to display.

=back

=head2 new_THelpWindow

  my $window = new_THelpWindow( $helpFile, $context );

Factory-style constructor using positional arguments. It takes the help file
and the help context number, in that order, and is equivalent to calling C<new>
with the named parameters C<hFile> and C<context>.

=head1 METHODS

=head2 getPalette

  my $palette = $window->getPalette();

Overrides the C<getPalette> method of the base view class. Returns a clone of
the C<cHelpWindow> palette defined in L<TUI::Help::Const>, as a
L<TPalette|TUI::Views::Palette> object.

=head1 SEE ALSO

L<TUI::Help>,
L<THelpViewer|TUI::Help::HelpViewer>,
L<THelpFile|TUI::Help::HelpFile>,
L<TWindow|TUI::Views::Window>

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
