package TUI::Vision;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Const;
use TUI::Objects;
use TUI::App;
use TUI::Views;
use TUI::Dialogs;
use TUI::Menus;
use TUI::Drivers;
use TUI::Gadgets;
use TUI::StdDlg;
use TUI::MsgBox;
use TUI::TextView;
use TUI::Memory;
use TUI::Validate;
use TUI::toolkit;

sub import {
  my $target = caller;
  TUI::Const->import::into( $target, qw( :all ) );
  TUI::Objects->import::into( $target );
  TUI::App->import::into( $target );
  TUI::Views->import::into( $target );
  TUI::Dialogs->import::into( $target );
  TUI::Menus->import::into( $target );
  TUI::Drivers->import::into( $target );
  TUI::Gadgets->import::into( $target );
  TUI::StdDlg->import::into( $target );
  TUI::MsgBox->import::into( $target );
  TUI::TextView->import::into( $target );
  TUI::Memory->import::into( $target );
  TUI::Validate->import::into( $target );
  TUI::toolkit->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::Const->unimport::out_of( $caller );
  TUI::Objects->unimport::out_of( $caller );
  TUI::App->unimport::out_of( $caller );
  TUI::Views->unimport::out_of( $caller );
  TUI::Dialogs->unimport::out_of( $caller );
  TUI::Menus->unimport::out_of( $caller );
  TUI::Drivers->unimport::out_of( $caller );
  TUI::Gadgets->unimport::out_of( $caller );
  TUI::StdDlg->unimport::out_of( $caller );
  TUI::MsgBox->unimport::out_of( $caller );
  TUI::TextView->unimport::out_of( $caller );
  TUI::Memory->unimport::out_of( $caller );
  TUI::Validate->unimport::out_of( $caller );
  TUI::toolkit->unimport::out_of( $caller );
}

1;

__END__

=pod

=head1 NAME

TUI::Vision - Perl TUI Framework (Turbo Vision 2.0 Port)

=head1 SYNOPSIS

  use TUI::Vision;

  # Imports the framework aggregators (Objects, App, Views, Dialogs,
  # Menus, Drivers, Gadgets, StdDlg, MsgBox, TextView, Memory, Validate)
  # and the toolkit helpers into your package.

=head1 DESCRIPTION

TUI::Vision is the top-level umbrella module of the framework.

It aggregates and re-exports the main subsystem modules through
C<Import::Into>, so applications can import the common TUI::Vision surface via
a single C<use TUI::Vision;> statement.

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

Contributors are documented in the POD of the respective framework modules.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
