use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Drivers::Colors', qw(
    BIOStoXTerm16
    RGBtoBIOS
    RGBtoXTerm16
    RGBtoXTerm256
    XTerm16toBIOS
    XTerm256toRGB
    XTerm256toXTerm16
  );
}

ok defined &BIOStoXTerm16,    'BIOStoXTerm16';
ok defined &RGBtoBIOS,        'RGBtoBIOS';
ok defined &RGBtoXTerm16,     'RGBtoXTerm16';
ok defined &RGBtoXTerm256,    'RGBtoXTerm256';
ok defined &XTerm16toBIOS,    'XTerm16toBIOS';
ok defined &XTerm256toRGB,    'XTerm256toRGB';
ok defined &XTerm256toXTerm16,'XTerm256toXTerm16';

ok defined BIOStoXTerm16(0xF),      'BIOStoXTerm16 call';
ok defined RGBtoBIOS(0x7F00BB),     'RGBtoBIOS call';
ok defined RGBtoXTerm16(0x7F00BB),  'RGBtoXTerm16 call';
ok defined RGBtoXTerm256(0x7F00BB), 'RGBtoXTerm256 call';

ok defined XTerm16toBIOS(15),       'XTerm16toBIOS call';
ok defined XTerm256toRGB(196),      'XTerm256toRGB call';
ok defined XTerm256toXTerm16(196),  'XTerm256toXTerm16 call';

done_testing;
