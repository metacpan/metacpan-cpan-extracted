use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Parse::Win32Registry') };

is($Parse::Win32Registry::VERSION, '1.1', 'correct version');
can_ok('Parse::Win32Registry', 'new');
can_ok('Parse::Win32Registry', 'convert_filetime_to_epoch_time');
can_ok('Parse::Win32Registry', 'iso8601');
can_ok('Parse::Win32Registry', 'hexdump');
can_ok('Parse::Win32Registry', 'unpack_windows_time');
can_ok('Parse::Win32Registry', 'unpack_string');
can_ok('Parse::Win32Registry', 'unpack_unicode_string');
can_ok('Parse::Win32Registry', 'unpack_sid');
can_ok('Parse::Win32Registry', 'unpack_ace');
can_ok('Parse::Win32Registry', 'unpack_acl');
can_ok('Parse::Win32Registry', 'unpack_security_descriptor');
