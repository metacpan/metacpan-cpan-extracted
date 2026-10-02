use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util qw( reftype );

BEGIN {
  eval {
    require TUI::Drivers::HardwareInfo::Termbox;
    1;
  } or plan skip_all => 'Termbox backend is not available';
}

BEGIN {
  use TUI::Drivers::HardwareInfo;
  plan skip_all => 'Termbox backend not selected'
    unless THardwareInfo->isa('TUI::Drivers::HardwareInfo::Termbox');

  use_ok 'TUI::Drivers::Const', qw( smCO80 );
}

ok( THardwareInfo, 'THardwareInfo exists' );

can_ok(
  THardwareInfo,
  qw(
    getTickCount
    getPlatform
    setCaretSize
    getCaretSize
    setCaretPosition
    isCaretVisible
    getScreenRows
    getScreenCols
    getScreenMode
    setScreenMode
    clearScreen
    screenWrite
    allocateScreenBuffer
    freeScreenBuffer
  )
);

#
# Platform
#

ok(
  THardwareInfo->getPlatform(),
  'platform detected'
);

#
# Tick counter
#

cmp_ok(
  THardwareInfo->getTickCount(),
  '>=',
  0,
  'tick count available'
);

#
# Caret handling
#

my $old_size = THardwareInfo->getCaretSize();

lives_ok {
  THardwareInfo->setCaretSize( 10 );
}
'setCaretSize lives';

cmp_ok(
  THardwareInfo->getCaretSize(),
  '>',
  0,
  'caret size available'
);

lives_ok {
  THardwareInfo->setCaretSize( $old_size );
}
'caret size restored';

ok(
  defined THardwareInfo->isCaretVisible(),
  'caret visibility available'
);

#
# Screen information
#

cmp_ok(
  THardwareInfo->getScreenRows(),
  '>=',
  0,
  'screen rows available'
);

cmp_ok(
  THardwareInfo->getScreenCols(),
  '>=',
  0,
  'screen cols available'
);

ok(
  defined THardwareInfo->getScreenMode(),
  'screen mode available'
);

#
# Screen buffer
#

my $buffer = THardwareInfo->allocateScreenBuffer();

isa_ok(
  $buffer,
  'ARRAY',
  'allocateScreenBuffer'
);

if ( @$buffer ) {

  is(
    reftype( $buffer->[0] ),
    'ARRAY',
    'screen cell is arrayref'
  );

  is(
    scalar @{ $buffer->[0] },
    2,
    'screen cell contains char and attr'
  );

  cmp_ok(
    scalar( @$buffer ),
    '>=',
    80 * 50,
    'buffer has minimum TV size'
  );
} #/ if ( @$buffer )

THardwareInfo->freeScreenBuffer( $buffer );

is_deeply(
  $buffer,
  [],
  'freeScreenBuffer clears buffer'
);

done_testing();
