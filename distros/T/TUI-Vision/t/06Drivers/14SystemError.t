use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Drivers::HardwareInfo';
  use_ok 'TUI::Drivers::SystemError';
}

# Test TSystemError
my $error = TSystemError();
ok( $error, 'TSystemError exists' );
can_ok( $error, 'resume' );
can_ok( $error, 'suspend' );

# Test global variables
ok(
  defined( $TUI::Drivers::SystemError::ctrlBreakHit ),
  'ctrlBreakHit is defined'
);
ok( 
  defined( $TUI::Drivers::SystemError::saveCtrlBreak ),
  'saveCtrlBreak is defined'
);

# Test methods
lives_ok { $error->resume() } 'resume() does not die';
lives_ok { $error->suspend() } 'suspend() does not die';

done_testing();
