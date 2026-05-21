use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw(
    :evXXXX
    kbLeft
    kbRight
    kbHome
    kbEnd
    kbBack
    kbDel
    kbIns
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Const', qw( :sfXXXX );
  use_ok 'TUI::Dialogs::InputLine';
  require_ok 'TUI::toolkit';
}

# Mock subclass to intercept drawing/UI-related calls
BEGIN {
  package MyInputLine;
  use TUI::toolkit;
  extends 'TUI::Dialogs::InputLine';

  # Just record that these methods were called; no real UI required
  sub drawView  { ::pass('drawView called') }
  sub writeLine { ::pass('writeLine called') }
  sub setCursor { ::pass('setCursor called') }

  $INC{'MyInputLine.pm'} = 1;
}

# Simple mock validator
BEGIN {
  package MyValidator;
  sub new {
    my ( $class, %args ) = @_;
    $args{transfer_ok} //= 0;    # value returned by transfer()
    $args{valid_input} //= 1;    # value returned by isValidInput()
    return bless \%args, $class;
  }
  sub transfer {
    my ( $self, $data, $rec, $mode ) = @_;
    # For this test we only care that the return value controls setData()
    return $self->{transfer_ok};
  }
  sub isValidInput {
    my ( $self, $data, $noAutoFill ) = @_;
    # Do not modify $data here; just indicate whether it is valid
    return $self->{valid_input};
  }
  sub shutDown { return; }

  $INC{'MyValidator.pm'} = 1;
} #/ BEGIN

use_ok 'MyInputLine';
use_ok 'MyValidator';

my (
  $bounds,
  $input,
);

# Test case for the constructor
subtest 'Object creation' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 1 );

  lives_ok { $input = MyInputLine->new( bounds => $bounds, maxLen => 10 ) }
    'Constructor lives';
  isa_ok( $input, TInputLine, 'Created object have the correct base class' );

  ok( exists $input->{maxLen}, 'maxLen initialized' );
  ok( exists $input->{data},   'data field exists' );

  # Ensure deterministic size for tests
  $input->{size}{x} //= 10;
  $input->{size}{y} //= 1;
};

# Test case for selectAll()
subtest 'selectAll' => sub {
  $input->{data} = 'Hello';
  $input->{size}{x} = 10;

  lives_ok { $input->selectAll(1) } 'selectAll(true) lives';

  is( $input->{selStart}, 0, 'selStart at 0 when enabled' );
  is( $input->{selEnd},   5, 'selEnd at end of string when enabled' );
  is( $input->{curPos},   5, 'curPos at end of string when enabled' );
  is( $input->{firstPos}, 0, 'firstPos adjusted to 0 for visible range' );
  is( $input->{anchor},   0, 'anchor set to 0 to avoid deselect' );

  lives_ok { $input->selectAll(0) } 'selectAll(false) lives';

  is( $input->{selStart}, 0, 'selStart remains 0 when disabled' );
  is( $input->{selEnd},   0, 'selEnd reset to 0 when disabled' );
  is( $input->{curPos},   0, 'curPos reset to 0 when disabled' );
};

# Test case for setData() without validator
subtest 'setData without validator' => sub {
  $input->{validator} = undef;
  $input->{maxLen}    = 5;
  $input->{size}{x}   = 10;

  my $src = 'ABCDEFGHIJ';

  lives_ok { $input->setData([$src]) } 'setData() without validator lives';

  is( $input->{data}, 'ABCDE', 'data truncated to maxLen characters' );
  is( $input->{curPos},   5, 'curPos at end after selectAll()' );
  is( $input->{selStart}, 0, 'selStart at 0 after selectAll()' );
  is( $input->{selEnd},   5, 'selEnd at end after selectAll()' );
};

# Test case for setData() with validator (transfer return value controls copy)
subtest 'setData with validator' => sub {
  my $validator = MyValidator->new( transfer_ok => 0 );
  $input->{validator} = $validator;
  $input->{maxLen}    = 5;
  $input->{size}{x}   = 10;

  # transfer() returns 0 -> copy branch is executed
  lives_ok { $input->setData(['ABCDEFG']) }
    'setData() with validator (transfer=0) lives';

  is( $input->{data}, 'ABCDE', 'data copied when transfer() returns 0' );

  # transfer() returns non-zero -> copy branch is skipped
  $validator->{transfer_ok} = 1;
  $input->{data}            = 'XXXX';

  lives_ok { $input->setData(['ABCDEFG']) }
    'setData() with validator (transfer!=0) lives';

  is(
    $input->{data},
    'XXXX',
    'data not overwritten when transfer() returns non-zero'
  );
};

# Test case for setState() and interaction with selectAll()
subtest 'setState / selectAll integration' => sub {
  $input->{data}     = 'Hello';
  $input->{size}{x}  = 10;
  $input->{state}    = 0;
  $input->{selStart} = 0;
  $input->{selEnd}   = 0;
  $input->{curPos}   = 0;
  $input->{firstPos} = 0;
  $input->{anchor}   = -1;

  lives_ok { $input->setState( sfSelected, 1 ) }
    'setState(sfSelected, 1) lives';

  is( $input->{selStart}, 0, 'selStart after selecting' );
  is( $input->{selEnd},   5, 'selEnd at end after selecting' );
  is( $input->{curPos},   5, 'curPos at end after selecting' );

  lives_ok { $input->setState( sfSelected, 0 ) }
    'setState(sfSelected, 0) lives';

  is( $input->{selEnd}, 0, 'selEnd cleared after deselecting' );
};

# Test case for setValidator() and destruction of old validator
subtest 'setValidator' => sub {
  my $v1 = MyValidator->new();
  my $v2 = MyValidator->new();

  $input->{validator} = $v1;

  lives_ok { $input->setValidator($v2) }
    'setValidator() lives';

  is( $input->{validator}, $v2, 'validator replaced with new instance' );
};

# Very basic handleEvent() test: no effect when not selected
subtest 'handleEvent when not selected' => sub {
  my $event = TEvent->new(
    what    => evKeyDown,
    keyDown => { keyCode => kbLeft },
  );
  isa_ok( $event, TEvent, 'Event is a TEvent object' );

  # Ensure control is not in selected state
  $input->{state} &= ~sfSelected;

  lives_ok { $input->handleEvent($event) }
    'handleEvent() without sfSelected state lives';

  # Event should not be consumed when input line is not selected
  is( $event->{what}, evKeyDown, 'event.what unchanged when not selected' );
};

done_testing();
