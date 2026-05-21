package TUI::App::ProgInit;
# ABSTRACT: program initialization helper

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TProgInit
  new_TProgInit
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  CodeRef
  Object
);

sub TProgInit() { __PACKAGE__ }
sub new_TProgInit { __PACKAGE__->from(@_) }

# protected attributes
has createStatusLine => ( is => 'bare', default => sub { die 'required' } );
has createMenuBar    => ( is => 'bare', default => sub { die 'required' } );
has createDeskTop    => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      createStatusLine => CodeRef, { alias => 'cStatusLine' },
      createMenuBar    => CodeRef, { alias => 'cMenuBar' },
      createDeskTop    => CodeRef, { alias => 'cDeskTop' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($cStatusLine, $cMenuBar, $cDeskTop)
  state $sig = signature(
    method => 1,
    pos    => [CodeRef, CodeRef, CodeRef],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( cStatusLine => $args[0], cMenuBar => $args[1], 
    cDeskTop => $args[2] );
}

sub createStatusLine {    # $statusLine ($r)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $r ) = $sig->( @_ );
  my ( $class, $code ) = ( ref $self, $self->{createStatusLine} );
  return $class->$code( $r );
}

sub createMenuBar {    # $menuBar ($r)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $r ) = $sig->( @_ );
  my ( $class, $code ) = ( ref $self, $self->{createMenuBar} );
  return $class->$code( $r );
}

sub createDeskTop {    # $deskTop ($r)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $r ) = $sig->( @_ );
  my ( $class, $code ) = ( ref $self, $self->{createDeskTop} );
  return $class->$code( $r );
}

1

__END__

=pod

=head1 NAME

TUI::App::ProgInit - program initialization helper

=head1 SYNOPSIS

  use TUI::App::ProgInit;

  my $progInit = TProgInit->new(
    createStatusLine => \&initStatusLine,
    createMenuBar    => \&initMenuBar,
    createDeskTop    => \&initDeskTop,
  );

=head1 DESCRIPTION

C<TProgInit> encapsulates the initialization logic used by a TUI::Vision
application to create its main user interface components.

The class stores factory callbacks for creating the status line, menu bar, and
desktop views. These callbacks are invoked during application startup to build
the visible structure of the program.

C<TProgInit> is not a view and does not participate in the view hierarchy. It
exists solely to decouple application initialization from the concrete
construction of user interface elements.

=head1 CONSTRUCTOR

=head2 new

  my $progInit = TProgInit->new(
    createStatusLine => \&statusLineFactory,
    createMenuBar    => \&menuBarFactory,
    createDeskTop    => \&deskTopFactory
  );

Creates a new program initialization helper.

=over

=item createStatusLine

Code reference that is called with a C<TRect> argument and must return a
C<TStatusLine> object.

=item createMenuBar

Code reference that is called with a C<TRect> argument and must return a
C<TMenuBar> object.

=item createDeskTop

Code reference that is called with a C<TRect> argument and must return a
C<TDeskTop> object.

=back

=head2 new_TProgInit

  my $progInit = new_TProgInit(
    \&statusLineFactory,
    \&menuBarFactory,
    \&deskTopFactory
  );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 createStatusLine

  my $statusLine = $progInit->createStatusLine($rect);

Invokes the stored status line factory callback and returns a status line view
for the specified rectangle.

=head2 createMenuBar

  my $menuBar = $progInit->createMenuBar($rect);

Invokes the stored menu bar factory callback and returns a menu bar view for the
specified rectangle.

=head2 createDeskTop

  my $deskTop = $progInit->createDeskTop($rect);

Invokes the stored desktop factory callback and returns a desktop view for the
specified rectangle.

=head1 SEE ALSO

L<TUI::App::Program>,
L<TUI::App::Application>,
L<TUI::App::DeskInit>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
