
#! /usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Devel::StrictMode;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Dialogs::Button'
    or BAIL_OUT( 'Cannot load TUI::Dialogs::Button' );
  use_ok 'TUI::Dialogs::Const', qw( :bfXXXX );
  use_ok 'TUI::Views::Const',   qw( :sfXXXX );
  use_ok 'TUI::Views::Group';
  use_ok 'TUI::Drivers::Const', qw( :evXXXX );
}

sub unlock_value {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
}

# Common test data
my $bounds = TRect->new(
  ax => 0,  ay => 0,
  bx => 10, by => 3,
);

# Tests for BUILDARGS() arguments
subtest 'BUILDARGS() - valid arguments' => sub {
  my $button;
  lives_ok {
    $button = TUI::Dialogs::Button->new(
      bounds   => $bounds,
      title   => 'OK',
      command => 100,
      flags   => bfDefault,
    );
  } 'constructor lives with valid title/command/flags';
  isa_ok( $button, 'TUI::Dialogs::Button', 'object is of correct class' );

  is( $button->title,   'OK',      'title attribute set from title' );
  is( $button->command, 100,       'command attribute set from command' );
  is( $button->flags,   bfDefault, 'flags attribute set from flags' );
  ok( $button->{amDefault}, 'amDefault derived from bfDefault' );
}; #/ 'BUILDARGS()' => sub

subtest 'BUILDARGS() - invalid arguments' => sub {
  # These tests depend on STRICT mode in your environment. If STRICT is off,
  # you may want to skip or adjust this subtest.
  SKIP: {
    skip 'STRICT validation not enabled or not testable', 3 unless STRICT;

    dies_ok {
      TUI::Dialogs::Button->new(
        bounds   => $bounds,
        title   => undef,
        command => 100,
        flags   => bfDefault,
      );
    } 'constructor dies when title is undef';

    dies_ok {
      TUI::Dialogs::Button->new(
        bounds   => $bounds,
        title   => 'OK',
        command => 'NOT_NUMERIC',
        flags   => bfDefault,
      );
    } 'constructor dies when command is not numeric';

    dies_ok {
      TUI::Dialogs::Button->new(
        bounds   => $bounds,
        title   => 'OK',
        command => 100,
        flags   => 'FLAG',
      );
    } 'constructor dies when flags is not numeric';
  } #/ SKIP:
}; #/ 'BUILDARGS() - invalid arguments' => sub

# Tests for factory constructor from()
subtest 'from()' => sub {
  my $button;
  lives_ok { $button = new_TButton( $bounds, 'Cancel', 200, 0, ) } 
    'from() lives with correct arguments';
  isa_ok( $button, TButton, 'from() returns correct class' );

  is( $button->title,   'Cancel', 'from() sets title correctly' );
  is( $button->command, 200,      'from() sets command correctly' );
  is( $button->flags,   0,        'from() sets flags correctly' );
}; #/ 'from() helper constructor' => sub

# Tests for new() initialization
subtest 'new()' => sub {
  my $button;
  lives_ok { $button = new_TButton( $bounds, 'Apply', 300, bfDefault ) }
    'from() + BUILD() live';

  ok( $button->{amDefault}, 'amDefault set when bfDefault is present' );
  ok(
    $button->{options},
    'options initialized (selectable / first click / pre-/post-process)'
  );
  ok(
    $button->{eventMask},
    'eventMask initialized (evBroadcast should be enabled)'
  );
  ok(
    !( $button->{state} & sfDisabled ),
    'state does not contain sfDisabled (commandEnabled() always true)'
  );
}; #/ 'new()'

# Tests for DEMOLISH() : clears title safely
subtest 'DEMOLISH()' => sub {
  my $button;
  lives_ok { $button = new_TButton( $bounds, 'Quit', 400, 0 ) }
    'button created';
  lives_ok { $button->DEMOLISH( 0 ) } 'DEMOLISH() lives';
  is( $button->{title}, undef, 'title is cleared in DEMOLISH()' );
}; #/ 'DEMOLISH()

# Basic tests for makeDefault() and press()
subtest 'makeDefault() and press()' => sub {
  my $button = new_TButton( $bounds, 'Send', 600, bfBroadcast );
  can_ok( $button, qw( makeDefault press ) );
  lives_ok { $button->makeDefault( 1 ) } 'makeDefault(1) lives';
  lives_ok { $button->press() } 'press() lives';
};

done_testing();
