package TUI::App::Application;
# ABSTRACT: TApplication is a generic application as a basis for your own apps.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TApplication
  new_TApplication
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :Object );

use TUI::App::Program;
use TUI::Dialogs::HistoryViewer::HistList qw(
  initHistory
  doneHistory
);
use TUI::Drivers::EventQueue;
use TUI::Drivers::Screen;
use TUI::Drivers::SystemError;

sub TApplication() { __PACKAGE__ }
sub new_TApplication { __PACKAGE__->from(@_) }

extends TProgram;

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  initHistory();
  return;
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  doneHistory();
  return;
}

sub suspend {
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  TSystemError->suspend();
  TEventQueue->suspend();
  TScreen->suspend();
  # TVMemMgr->suspend();    # Release discardable memory.
  return;
}

sub resume {
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  TScreen->resume();
  TEventQueue->resume();
  TSystemError->resume();
  return;
}

1

__END__

=pod

=head1 NAME

TUI::App::Application - generic application base class

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TProgram
          TApplication

=head1 SYNOPSIS

  package MyApp;

  use Moo;
  use TUI::App;
  use TUI::Menus;
  use TUI::Views;

  extends TApplication;

  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return TMenuBar->new(
      bounds => $r,
      menu   => new_TSubMenu('~F~ile', kbAltF)
                + new_TMenuItem('E~x~it', cmQuit, kbAltX)
    );
  }

  package main;
  my $app = MyApp->new();
  $app->run();

=head1 DESCRIPTION

C<TApplication> is the standard base class for TUI::Vision applications.
It extends C<TProgram> with application-level initialization and shutdown
behavior and integrates system services such as event handling, screen
management, and history tracking.

In this C++-based port, C<TApplication> follows the Turbo Vision C++ model.
Pascal-specific constructs such as C<Init>, C<Done>, C<Load>, and C<Store> are
not part of the public API and are therefore not documented.

Most applications should derive directly from C<TApplication> rather than from
C<TProgram>.

=head2 Commonly Used Features

In typical projects, C<TApplication> is used as the main application base class
and customized by overriding initialization hooks such as C<initMenuBar()>,
C<initStatusLine()>, and, when needed, C<initDeskTop()>. The common runtime
flow is: create application object with C<< $app->new() >>, call C<run()>, and 
let the object lifecycle handle startup/shutdown services inherited from 
C<TProgram> plus C<TApplication>-specific history initialization.

The C<suspend()> and C<resume()> methods are primarily used when the
application temporarily gives up control of screen/event processing (for
example around external operations), then restores TUI::Vision services.

=head1 CONSTRUCTOR

=head2 new

  my $app = TApplication->new();

Creates a new application object.

Application-level initialization is performed automatically as part of object
construction.

=head2 new_TApplication

  my $app = new_TApplication();

Factory-style constructor using positional arguments.

This constructor is provided for compatibility with traditional Turbo Vision
construction patterns.

=head1 DESTRUCTOR

=head2 DEMOLISH

  $self->DEMOLISH($in_global_destruction);

Releases application-level resources during object destruction.

This method is part of the Perl object lifecycle and ensures that internal
references related to system services and history management are released.

=head1 METHODS

=head2 resume

  $app->resume();

Resumes suspended system services including event processing and screen output.

=head2 suspend

  $app->suspend();

Suspends system services such as event processing, screen output, and memory
management.

=head1 EXAMPLE

The following example shows a minimal TUI::Vision application derived from
C<TApplication>. It demonstrates menu creation, event handling, and the use of
a dialog.

  package THelloApp;

  use strict;
  use warnings;

  use Moo;
  use TUI::Objects;
  use TUI::Menus;
  use TUI::Drivers;
  use TUI::App;
  use TUI::Views;
  use TUI::Dialogs;

  extends TApplication;

  use constant {
    GreetThemCmd => 100,
  };

  sub greetingBox {
    my ($self) = @_;

    my $d = new_TDialog(
      new_TRect(25, 5, 55, 16),
      "Hello, World!"
    );

    $d->insert(
      new_TStaticText(
        new_TRect(3, 5, 15, 6),
        "How are you?"
      )
    );

    $d->insert(
      new_TButton(
        new_TRect(16, 2, 28, 4),
        "Terrific",
        cmCancel,
        bfNormal
      )
    );

    $d->insert(
      new_TButton(
        new_TRect(16, 4, 28, 6),
        "Ok",
        cmCancel,
        bfNormal
      )
    );

    $d->insert(
      new_TButton(
        new_TRect(16, 6, 28, 8),
        "Lousy",
        cmCancel,
        bfNormal
      )
    );

    $d->insert(
      new_TButton(
        new_TRect(16, 8, 28, 10),
        "Cancel",
        cmCancel,
        bfNormal
      )
    );

    $deskTop->execView($d);
    $self->destroy($d);
  }

  sub handleEvent {
    my ($self, $event) = @_;

    $self->SUPER::handleEvent($event);

    if ($event->{what} == evCommand) {
      if ($event->{message}{command} == GreetThemCmd) {
        $self->greetingBox();
        $self->clearEvent($event);
      }
    }
  }

  sub initMenuBar {
    my ($class, $r) = @_;

    $r->{b}{y} = $r->{a}{y} + 1;

    return new_TMenuBar(
      $r,
      new_TSubMenu("~H~ello", kbAltH)
        + new_TMenuItem("~G~reeting...", GreetThemCmd, kbAltG)
        + newLine
        + new_TMenuItem("E~x~it", cmQuit, kbAltX, hcNoContext, "Alt-X")
    );
  }

  sub initStatusLine {
    my ($class, $r) = @_;

    $r->{a}{y} = $r->{b}{y} - 1;

    return new_TStatusLine(
      $r,
      new_TStatusDef(0, 0xFFFF)
        + new_TStatusItem("~Alt-X~ Exit", kbAltX, cmQuit)
        + new_TStatusItem("", kbF10, cmMenu)
    );
  }

  package main;

  my $app = new_THelloApp();
  $app->run();

=head1 SEE ALSO

L<TUI::App::Program>,
L<TUI::Views::View>,
L<TUI::Views::Group>

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
