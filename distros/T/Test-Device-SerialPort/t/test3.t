use lib '.','./t','./lib','../lib';
# can run from here or distribution base

use Test::More;
plan tests => 133;

## some online discussion of issues with use_ok, so just sanity check
cmp_ok($AltPort::VERSION, '>=', 0.03, 'VERSION check');

# Some OS's (BSD, linux on Alpha, etc.) can't test pulse timing
my $TICKTIME=0;

use AltPort qw( :STAT 0.05 );

use strict;
use warnings;

## verifies the (0, 1) list returned by binary functions
sub test_bin_list {
    return undef unless (@_ == 2);
    return undef unless (0 == shift);
    return undef unless (1 == shift);
    return 1;
}

sub is_zero {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(shift == 0, shift);
}

sub is_bad {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(!shift, shift);
}

# assume a "vanilla" port on "COM1" to check alias and device

my $file = "COM1";

my $cfgfile = "$file"."_test.cfg";
my $tstlock = "$file"."_lock.cfg";
$cfgfile =~ s/.*\///;
$tstlock =~ s/.*\///;

my $fault = 0;
my $ob;
my $pass;
my $fail;
my $in;
my $in2;
my @opts;
my $out;
my $err;
my $blk;
my $e;
my %required_param;
my @necessary_param = AltPort->set_test_mode_active(1);

unlink $cfgfile;
foreach $e (@necessary_param) { $required_param{$e} = 0; }

# 2: Constructor

ok($ob = AltPort->new ($file), "new $file");
die unless ($ob);    # next tests would die at runtime

# 3 - 8: object debug method

is_bad( scalar $ob->debug(), 'object debug init');
ok( scalar $ob->debug("T"), 'T' );
ok( scalar $ob->debug(), 'read debug state' );
is_bad( scalar $ob->debug("2"), 'invalid debug turns off' );
is_bad( scalar $ob->debug(), 'confirm off' );

@opts = $ob->debug();
ok(test_bin_list(@opts), 'binary_opt_array');

#### 9 - 29: Check Port Capabilities 

ok($ob->can_baud, 'can_baud');
ok($ob->can_databits, 'can_databits');
ok($ob->can_stopbits, 'can_stopbits');
ok($ob->can_dtrdsr, 'can_dtrdsr');
ok($ob->can_handshake, 'can_handshake');
ok($ob->can_parity_check, 'can_parity_check');
ok($ob->can_parity_config, 'can_parity_config');
ok($ob->can_parity_enable, 'can_parity_enable');
ok($ob->can_rtscts, 'can_ctsrts');
ok($ob->can_xonxoff, 'can_xonxoff');
ok($ob->can_total_timeout, 'can_total_timeout');
ok($ob->can_xon_char, 'can_xon_char');

is_zero($ob->can_spec_char, 'can_spec_char');
is_zero($ob->can_16bitmode, 'can_16bitmode');

if ($^O eq 'MSWin32') {
	ok($ob->can_rlsd, 'can_rlsd');
	ok($ob->can_interval_timeout, 'can_interval_timeout');
	is_zero($ob->can_ioctl, 'can_ioctl');
	is($ob->device, '\\\\.\\'.$file, 'Win32 device');
} else {
	is_zero($ob->can_rlsd, 'can_rlsd');
	is_zero($ob->can_interval_timeout, 'can_interval_timeout');
	ok($ob->can_ioctl, 'can_ioctl');
	is($ob->alias, $file, 'device not implemented');
}
is($ob->alias, $file, 'alias init');
ok($ob->is_rs232, 'is_rs232');
is_zero($ob->is_modem, 'is_modem');

#### 30 - 70: Set Basic Port Parameters 

## 30 - 35: Baud (Valid/Invalid/Current)

@opts=$ob->baudrate;		# list of allowed values
ok(1 == grep(/^9600$/, @opts), '9600 baud in list');
ok(0 == grep(/^9601/, @opts), '9601 baud not in list'); # force scalar context

ok($in = $ob->baudrate, 'read baudrate');
ok(1 == grep(/^$in$/, @opts), "confirm $in in baud array");
is_bad(scalar $ob->baudrate(9601), 'cannot set 9601 baud');
ok($ob->baudrate(9600), 'can set 9600 baud');
    # leaves 9600 pending

## 36 - 41: Parity (Valid/Invalid/Current)

@opts=$ob->parity;		# list of allowed values
ok(1 == grep(/none/, @opts), 'parity none in list');
ok(0 == grep(/any/, @opts), 'parity any not in list');

ok($in = $ob->parity, 'read parity');
ok(1 == grep(/^$in$/, @opts), "confirm $in in parity array");

is_bad(scalar $ob->parity("any"), 'cannot set any parity');
ok($ob->parity("none"), 'can set none parity');
    # leaves "none" pending

## 42 - 47: Databits (Valid/Invalid/Current)

@opts=$ob->databits;		# list of allowed values
ok(1 == grep(/8/, @opts), '8 databits in list');
ok(0 ==  grep(/4/, @opts), '4 databits not in list');

ok($in = $ob->databits, 'read databits');
ok(1 == grep(/^$in$/, @opts), "confirm $in databits in list");

is_bad(scalar $ob->databits(3), 'cannot set 3 databits');
ok($ob->databits(8), 'can set 8 databits');
    # leaves 8 pending

## 48 - 53: Stopbits (Valid/Invalid/Current)

@opts=$ob->stopbits;		# list of allowed values
ok(1 == grep(/2/, @opts), '2 stopbits in list');
ok(0 == grep(/1.5/, @opts), '1.5 stopbits not in list');

ok($in = $ob->stopbits, 'read stopbits');
ok(1 == grep(/^$in$/, @opts), "confirm $in stopbits in list");

is_bad(scalar $ob->stopbits(3), 'cannot set 3 stopbits');
ok($ob->stopbits(1), 'can set 1 stopbit');
    # leaves 1 pending

## 54 - 59: Handshake (Valid/Invalid/Current)

@opts=$ob->handshake;		# list of allowed values
ok(1 == grep(/none/, @opts), 'handshake none in list');
ok(0 ==  grep(/moo/, @opts), 'handshake moo not in list');

ok($in = $ob->handshake, 'read handshake');
ok(1 == grep(/^$in$/, @opts), "confirm handshake $in in list");

is_bad(scalar $ob->handshake("moo"), 'cannot set handshake moo');
ok($ob->handshake("rts"), 'can set handshake rts');

## 60 - 66: Buffer Size

($in, $out) = $ob->buffer_max(512);
is_bad(defined $in, 'invalid buffer_max command');
($in, $out) = $ob->buffer_max;
ok(defined $in, 'read in buffer_max');
ok(defined $out, 'read out buffer_max');

if (($in > 0) and ($in < 4096))		{ $in2 = $in; } 
else					{ $in2 = 4096; }

if (($out > 0) and ($out < 4096))	{ $err = $out; } 
else					{ $err = 4096; }

ok(scalar $ob->buffers($in2, $err), 'valid set buffer_max');

@opts = $ob->buffers(4096, 4096, 4096);
is_bad(defined $opts[0], 'invalid buffers command');
($in, $out)= $ob->buffers;
ok($in2 == $in, 'check buffers in setting');
ok($out == $err, 'check buffers out setting');

## 67 - 70: Other Parameters (Defaults)

is($ob->alias("TestPort"), 'TestPort', 'alias');
is_zero(scalar $ob->parity_enable(0), 'parity disable');
ok($ob->write_settings, 'write_settings');
ok($ob->binary, 'binary');

## 71 - 72: Read Timeout Initialization

is_zero(scalar $ob->read_const_time, 'read_const_time');
is_zero(scalar $ob->read_char_time, 'read_char_time');

## 73 - 78: No Handshake, Polled Write

is($ob->handshake("none"), 'none', 'set handshake for write');

$e="testing is a wonderful thing - this is a 60 byte long string";
#   123456789012345678901234567890123456789012345678901234567890
my $line = "\r\n$e\r\n$e\r\n$e\r\n";	# about 195 MS at 9600 baud

my $tick=$ob->get_tick_count;
sleep 2;
my $tock=$ob->get_tick_count;
$err=$tock - $tick;
unless ($err > 1950 && $err < 2100) {
	$TICKTIME = 1;	# can't test pulse timing
}
print "<2000> elapsed time=$err\n";

$pass=$ob->write($line);
ok($pass == 188, 'write character count');
ok (1, 'skip write timeout');

ok(scalar $ob->purge_tx, 'purge_tx');
ok(scalar $ob->purge_rx, 'purge_rx');
ok(scalar $ob->purge_all, 'purge_all');

## 79 - 84: Optional Messages

@opts = $ob->user_msg;
ok(test_bin_list(@opts), 'user_msg_array');
is_zero(scalar $ob->user_msg, 'user_msg init OFF');
ok(1 == $ob->user_msg(1), 'user_msg_ON');

@opts = $ob->error_msg;
ok(test_bin_list(@opts), 'error_msg_array');
is_zero(scalar $ob->error_msg, 'error_msg init OFF');
ok(1 == $ob->error_msg(1), 'error_msg_ON');

## 85 - 91: Save and Check Configuration

ok(scalar $ob->save($cfgfile), 'save');

is($ob->baudrate, 9600, 'baudrate');
is($ob->parity, 'none', 'parity');

is($ob->databits, 8, 'databits');
is($ob->stopbits, 1, 'stopbits');


ok (300 == $ob->read_const_time(300), 'read_const_time');
ok (20 == $ob->read_char_time(20), 'read_char_time');

## 92 - 107: Output bits and pulses

    ok ($ob->dtr_active(0), 'dtr inactive');
    $tick=$ob->get_tick_count;
    ok ($ob->pulse_dtr_on(100), 'pulse_dtr_on');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    SKIP: {
        skip "Can't time pulses", 1 if $TICKTIME;
        is_bad (($err < 180) or ($err > 265), 'dtr pulse timing');
    }
    print "<200> elapsed time=$err\n";
    
    ok ($ob->dtr_active(1), 'dtr active');
    $tick=$ob->get_tick_count;
    ok ($ob->pulse_dtr_off(200), 'pulse_dtr_off');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    SKIP: {
        skip "Can't time pulses", 1 if $TICKTIME;
        is_bad (($err < 370) or ($err > 485), 'dtr pulse timing');
    }
    print "<400> elapsed time=$err\n";
   
    SKIP: {
        skip "Can't RTS", 7 unless $ob->can_rtscts();
	
	ok ($ob->rts_active(0), 'rts inactive');
    	$tick=$ob->get_tick_count;
	ok ($ob->pulse_rts_on(150), 'pulse rts on');
	$tock=$ob->get_tick_count;
	$err=$tock - $tick;
	SKIP: {
            skip "Can't time pulses", 1 if $TICKTIME;
	    is_bad (($err < 275) or ($err > 365), 'pulse rts timing');
	}
	print "<300> elapsed time=$err\n";
    
	ok ($ob->rts_active(1), 'rts active');
	$tick=$ob->get_tick_count;
	ok ($ob->pulse_rts_off(50), 'pulse rts off');
	$tock=$ob->get_tick_count;
	$err=$tock - $tick;
	SKIP: {
            skip "Can't time pulses", 1 if $TICKTIME;
	    is_bad (($err < 80) or ($err > 145), 'pulse rts timing');
	}
	print "<100> elapsed time=$err\n";

	ok ($ob->rts_active(0), 'reset rts inactive');
    }
    
    ok ($ob->dtr_active(0), 'reset dtr inactive');
    is($ob->handshake("rts"), 'rts', 'set handshake');
    is($ob->handshake("none"), 'none', 'release handshake block');

## 108 - 119: Modem Status Bits

    ok(MS_CTS_ON, 'MS_CTS_ON');
    ok(MS_DSR_ON, 'MS_DSR_ON');
    ok(MS_RING_ON, 'MS_RING_ON');
    ok(MS_RLSD_ON, 'MS_RLSD_ON');
    $blk = MS_CTS_ON | MS_DSR_ON | MS_RING_ON | MS_RLSD_ON;
    ok(defined($in = $ob->modemlines), 'modemlines');
    ok (1, 'skip modemlines');

    is(ST_BLOCK, 0, 'ST_BLOCK');
    is(ST_INPUT, 1, 'ST_INPUT');
    is(ST_OUTPUT, 2, 'ST_OUTPUT');
    is(ST_ERROR, 3, 'ST_ERROR');

## 120 - 372: Status

    $ob->reset_error;
    is(scalar (@opts = $ob->is_status), 4, 'is_status array');

    # default should be $in=0, $out=0, $blk=0, $err=0
    ($blk, $in, $out, $err)=@opts;

    is($blk, 0, 'blocking bits');
    is($in, 0, 'input count');
    is($out, 0, 'output count');
    is($err, 0, 'error bits');

    ($blk, $in, $out, $err)=$ob->is_status(0x150, 0xaa);	# test only
    is($err, 0x150, 'error_bits forced');
    is($blk, 0xaa, 'blocking bits forced');

    ($blk, $in, $out, $err)=$ob->is_status(0, 0x55);	# test only
    is($err, 0x150, 'error_bits retained');
    is($blk, 0x55, 'blocking bits forced alt');

    ($blk, $in, $out, $err)=$ob->is_status(0x0f);	# test only
    is($err, 0x15f, 'error bits add');
    is($blk, 0, 'blocking bits reset');

    is($ob->reset_error, 0x15f, 'reset_error');

    ($blk, $in, $out, $err)=$ob->is_status;
    is($err, 0, 'error bits');

    $tick=$ob->get_tick_count;
    ok ($ob->pulse_break_on(250), 'pulse break on');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    SKIP: {
        skip "Can't time pulses", 1 if $TICKTIME;
	is_bad (($err < 235) or ($err > 900), 'pulse break timing');
    }
    print "<500> elapsed time=$err\n";

ok($ob->close, 'close');	# 120: finish gracefully

    # destructor = DESTROY method
undef $ob;					# Don't forget this one!!

