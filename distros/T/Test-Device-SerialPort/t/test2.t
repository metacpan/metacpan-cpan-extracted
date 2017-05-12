use lib '.','./t','./lib','../lib';
# can run from here or distribution base

use Test::More;
plan tests => 124;
## some online discussion of issues with use_ok, so just sanity check
cmp_ok($Test::Device::SerialPort::VERSION, '>=', 0.03, 'VERSION check');

# USB and virtual ports can't test output timing, first fail will set this
my $BUFFEROUT=0;

use Test::Device::SerialPort qw( :STAT 0.03 );

use strict;
use warnings;

my $file = "COM1";
my $cfgfile = "COM1_test.cfg";

my $ob;
my $in;
my $in2;
my $instead;
my @opts;
my $out;
my $blk;
my $err;
my $e;
my $tick;
my $tock;
my $patt;
my @necessary_param = Test::Device::SerialPort->set_test_mode_active(1);

# 2: Constructor

ok($ob = Test::Device::SerialPort->new ($file), "new $file");
die unless ($ob);    # next tests would die at runtime

#### 3 - 26: Check Port Initialization

is (scalar $ob->baudrate, 9600, 'baudrate init');
is (scalar $ob->parity, 'none', 'parity');
is (scalar $ob->handshake, 'none', 'handshake');
is (scalar $ob->databits, 8, 'databits');
is (scalar $ob->stopbits, 1, 'stopbits');
is (scalar $ob->user_msg, 0, 'user_msg');
is (scalar $ob->error_msg, 0, 'error_msg');
is ($ob->read_char_time, 0, 'read_char_time');
is ($ob->read_const_time, 0, 'read_const_time');
is (scalar $ob->debug, 0, 'debug');
is ($ob->set_no_random_data, 0, 'set_no_random_data');
is ($ob->device, ($^O eq "MSWin32") ? '\\\\.\\COM1' :'COM1', 'device');
is ($ob->alias, 'COM1', 'alias');
is ($ob->input, chr(0xa5), 'fake input');
is ($ob->binary, 1, 'binary');

($in, $out)= $ob->buffers();
is ($in, 4096, 'buffer in');
is ($out, 4096, 'buffer out');

### 27 - 65: Defaults for streamline and lookfor

is ($ob->set_no_random_data, 0, 'initial no_random_data');
ok ($ob->set_no_random_data(1), 'set no_random_data');
@opts = $ob->are_match;
is (scalar @opts, 1, 'are match');
is ($opts[0], "\n", 'new line as default');
is ($ob->lookclear, 1, 'lookclear');
is ($ob->lookfor, "", 'lookfor');
is ($ob->streamline, "", 'streamline');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "", 'input that MATCHED');
is ($out, "", 'input AFTER match');
is ($patt, "", 'PATTERN that matched');
is ($instead, "", 'input INSTEAD of matching');
is ($ob->matchclear, "", 'MATCH was first');

@opts = $ob->are_match ("END","Bye");
is ($#opts, 1, 'are_match');
is ($opts[0], "END", 'value=END');
is ($opts[1], "Bye", 'value = Bye');
is ($ob->lookclear("Good Bye, Hello"), 1, 'lookclear load data');
is ($ob->lookfor, "Good ", 'lookfor find match');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "Bye", 'MATCHED');
is ($out, ", Hello", 'AFTER');
is ($patt, "Bye", 'PATTERN');
is ($instead, "", 'INSTEAD');
is ($ob->matchclear, "Bye", 'what MATCHED');
is ($ob->matchclear, "", 'reset after reading');

is ($ob->lookclear("Bye, Bye, Love. The END has come"), 1, 'load new string');
is ($ob->lookfor, "", 'match at beginning');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "Bye", 'MATCHED');
is ($out, ", Bye, Love. The END has come", 'string AFTER');
is ($patt, "Bye", 'PATTERN');
is ($instead, "", 'INSTEAD');
is ($ob->matchclear, "Bye", 'what MATCHED');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "", 'matchclear');
is ($out, ", Bye, Love. The END has come", 'other lastlook retained');
is ($patt, "Bye", 'PATTERN');
is ($instead, "", 'INSTEAD');

is ($ob->lookfor, ", ", 'next string BEFORE match');
($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "Bye", 'MATCHED');
is ($out, ", Love. The END has come", 'string AFTER');
is ($patt, "Bye", 'PATTERN');
is ($instead, "", 'INSTEAD');
is ($ob->matchclear, "Bye", 'what MATCHED');

is ($ob->lookfor, ", Love. The ", 'next unmatched');
($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "END", 'MATCH other pattern');
is ($out, " has come", 'rest of string');
is ($patt, "END", 'other PATTERN');
is ($instead, "", 'INSTEAD');
is ($ob->matchclear, "END", 'matchclear');
is ($ob->lookfor, "", 'nothing else matched');
is ($ob->matchclear, "", 'not even at beginning');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "", 'no MATCH');
is ($patt, "", 'no PATTERN');
is ($instead, " has come", 'INSTEAD shows remainder');

is ($ob->lookclear("Good Bye, Hello"), 1, 'lookclear load for streamline');
is ($ob->streamline, "Good ", 'streamline');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "Bye", 'MATCHED');
is ($out, ", Hello", 'AFTER');
is ($patt, "Bye", 'PATTERN');
is ($instead, "", 'INSTEAD');
is ($ob->matchclear, "Bye", 'what MATCHED');
is ($ob->matchclear, "", 'reset after reading');

is ($ob->lookclear("First\nSecond\nThe END"), 1, 'lookclear load');
is ($ob->streamline, "First\nSecond\nThe ", 'streamline');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "END", 'MATCHED');
is ($out, "", 'nothing AFTER');
is ($patt, "END", 'PATTERN');
is ($instead, "", 'INSTEAD');

is ($ob->lookclear, 1, 'lookclear clears');
is ($ob->lookfor, "", 'check no data');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "", 'no MATCH');
is ($out, "", 'no AFTER');
is ($patt, "", 'no PATTERN');
is ($instead, "", 'NO INSTEAD');

@opts = $ob->are_match;
is ($#opts, 1, 'are_match');
is ($opts[0], "END", 'value=END');
is ($opts[1], "Bye", 'value = Bye');

@opts = $ob->are_match("\n");
is ($#opts, 0, 'are_match reset');
is ($opts[0], "\n", 'linefeed');

is ($ob->lookclear("Before\nAfter"), 1, 'lookclear load');
is ($ob->lookfor, "Before", 'lookfor match in middle');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "\n", 'MATCHED');
is ($out, "After", 'AFTER');
is ($patt, "\n", 'PATTERN');
is ($instead, "", 'INSTEAD');

is ($ob->lookfor, "", 'lookfor no match');
($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "", 'no MATCH');
is ($patt, "", 'no PATTERN');
is ($instead, "After", 'found AFTER');

@opts = $ob->are_match ("B*e","ab..ef","-re","12..56","END");
is ($#opts, 4, 're matches');
is ($opts[2], "-re", 're delimiter');
is ($ob->lookclear("Good Bye, the END, Hello"), 1, 'lookclear load');
is ($ob->lookfor, "Good Bye, the ", 'lookfor BEFORE');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "END", 'MATCHED');
is ($out, ", Hello", 'AFTER');
is ($patt, "END", 'PATTERN');
is ($instead, "", 'no INSTEAD');

is ($ob->lookclear("Good B*e, abcdef, 123456"), 1, 'lookclear load for re');
is ($ob->lookfor, "Good ", 'lookfor');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "B*e", 'wildcard MATCHED');
is ($out, ", abcdef, 123456", 'AFTER');
is ($patt, "B*e", 'PATTERN');
is ($instead, "", 'no INSTEAD');

is ($ob->lookfor, ", abcdef, ", 'lookfor');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "123456", 'MATCHED');
is ($out, "", 'nothing AFTER');
is ($patt, "12..56", 'PATTERN is re');
is ($instead, "", 'nothing INSTEAD');

undef $ob;
