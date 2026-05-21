package TUI::App;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::App::Const;
use TUI::App::Background;
use TUI::App::DeskInit;
use TUI::App::DeskTop;
use TUI::App::ProgInit;
use TUI::App::Program;
use TUI::App::Application;

sub import {
  my $target = caller;
  TUI::App::Const->import::into( $target, qw( :all ) );
  TUI::App::Background->import::into( $target );
  TUI::App::DeskInit->import::into( $target );
  TUI::App::DeskTop->import::into( $target );
  TUI::App::ProgInit->import::into( $target );
  TUI::App::Program->import::into( $target, qw ( /\S+/ ) );
  TUI::App::Application->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::App::Const->unimport::out_of( $caller );
  TUI::App::Background->unimport::out_of( $caller );
  TUI::App::DeskInit->unimport::out_of( $caller );
  TUI::App::DeskTop->unimport::out_of( $caller );
  TUI::App::ProgInit->unimport::out_of( $caller );
  TUI::App::Program->unimport::out_of( $caller );
  TUI::App::Application->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::App - Application layer for the TUI::Vision framework

=head1 SYNOPSIS

  package MyApp;

  use Moo;
  use TUI::Objects;
  use TUI::App;
  use TUI::Menus;

  extends TApplication;

  sub BUILDARGS {
    my $args = shift->SUPER::BUILDARGS( @_ ) || return;
    $args->{bounds} = new_TRect( 0, 0, 80, 25 );
    return $args;
  }

  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return new_TMenuBar( $r,
      new_TSubMenu( '~F~ile', hcNoContext ) +
        new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' )
    );
  }

  package main;

  my $app = MyApp->new();
  $app->run();

=head1 DESCRIPTION

TUI::App represents the application-level framework of TUI::Vision.
It corresponds to the Turbo Vision TProgram and TApplication layer and
provides the structural foundation for building complete TUI programs.

This module re-exports multiple application components, including:

=over 4

=item * L<Const|TUI::App::Const> -
Symbolic constants for application behavior.

=item * L<TBackground|TUI::App::Background> -
Default background view and screen initialization.

=item * L<TDeskInit|TUI::App::DeskInit> / L<TDeskTop|TUI::App::DeskTop> -
Desktop initialization and window management.

=item * L<TProgInit|TUI::App::ProgInit> -
Program startup sequence.

=item * L<TProgram|TUI::App::Program> -
Main program loop and event dispatching.

=item * L<TApplication|TUI::App::Application> -
High-level application object.

=back

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

Contributors are documented in the POD of the respective framework modules.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
