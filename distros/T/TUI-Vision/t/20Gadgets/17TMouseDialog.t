use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Drivers::Const', qw(
    evBroadcast
    evCommand
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Drivers::EventQueue';
  use_ok 'TUI::Views::Const', qw(
    cmCancel
    cmScrollBarChanged
    ofCentered
    ofSelectable
  );
  use_ok 'TUI::Views::ScrollBar';
  use_ok 'TUI::Gadgets::MouseDialog';
}

sub event {
  my ( $what, $command ) = @_;

  return TEvent->new(
    what    => $what,
    message => {
      command => $command,
    },
  );
}

subtest 'constructor' => sub {
  $TUI::Drivers::EventQueue::doubleDelay = 8;

  my $dialog;
  lives_ok { $dialog = new_TMouseDialog() } 'constructor lives';

  isa_ok( $dialog, TMouseDialog );
  is( $dialog->{title}, 'Mouse options', 'title initialized' );
  ok( $dialog->{options} & ofCentered, 'dialog is centered' );

  isa_ok( $dialog->{mouseScrollBar}, TScrollBar );
  ok(
    $dialog->{mouseScrollBar}{options} & ofSelectable,
    'scrollbar is selectable'
  );
  is(
    $dialog->{mouseScrollBar}{value}, 8,
    'scrollbar uses current double-click delay'
  );
  is( $dialog->{oldDelay}, 8, 'original delay saved' );
}; #/ 'constructor' => sub

subtest 'scrollbar change' => sub {
  $TUI::Drivers::EventQueue::doubleDelay = 8;

  my $dialog = new_TMouseDialog();
  $dialog->{mouseScrollBar}->setValue( 12 );

  my $event = event( evBroadcast, cmScrollBarChanged );
  lives_ok { $dialog->handleEvent( $event ) }
    'scrollbar change lives';

  is(
    $TUI::Drivers::EventQueue::doubleDelay, 12,
    'double-click delay updated'
  );
  is( $event->{what}, 0, 'event cleared' );
};

subtest 'cancel restores delay' => sub {
  $TUI::Drivers::EventQueue::doubleDelay = 8;

  my $dialog = new_TMouseDialog();
  $TUI::Drivers::EventQueue::doubleDelay = 12;

  my $event = event( evCommand, cmCancel );
  lives_ok { $dialog->handleEvent( $event ) } 'cancel lives';

  is(
    $TUI::Drivers::EventQueue::doubleDelay, 8,
    'original double-click delay restored'
  );
};

done_testing();
