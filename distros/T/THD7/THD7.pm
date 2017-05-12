package THD7;

require 5.004;

# David Nesting
# THD7.pm - A module for providing control to a TH-D7 radio via serial port
#
# Kevin Wittmer
# Version 1.3 - 3 April 2004
# Added support for APRS message send
#
# Kevin Wittmer
# Version 1.2 - 17 January 2004
# Added support for the Windows operating system
#
# David Nesting
# Version 1.1 - 17 April 1999
# Added support for: CH, DW, UP, FL, FQ, SC, TC, VR, VW, MON, SFT
#
# David Nesting
# Version 1.0 - 15 April 1999

BEGIN {
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	
	$VERSION = 1.30;

	@ISA = qw(Exporter);
	@EXPORT = qw(NOCALLBACK);
	%EXPORT_TAGS = (
		'constants' => [qw{ BAND_A BAND_B ON OFF KEY KEY_DATA ALL
		TIME CARRIER SEEK DATA BOTH SLOW FAST APO_30 APO_60
		ENGLISH METRIC MANUAL PTT AUTO NMEA POSITIVE NEGATIVE
		BLACK BLUE RED MAGENTA GREEN CYAN YELLOW WHITE
		HIGH LOW EL OPEN CLOSED FULL HALF AIR VHF_A VHF_B UHF }],
		'functions'	=> [qw{ ToStep FromStep ToTone FromTone ToPosit FromPosit }]
	);
	@EXPORT_OK = qw(BAND_A BAND_B ON OFF KEY KEY_DATA ALL
		TIME CARRIER SEEK DATA BOTH SLOW FAST APO_30 APO_60
		ENGLISH METRIC MANUAL PTT AUTO NMEA POSITIVE NEGATIVE
		BLACK BLUE RED MAGENTA GREEN CYAN YELLOW WHITE
		HIGH LOW EL OPEN CLOSED FULL HALF AIR VHF_A VHF_B UHF 
		ToStep FromStep ToTone FromTone ToPosit FromPosit
	);
}

use strict;
use Symbol;
use Carp;

use constant (BAND_A	=>	0);
use constant (BAND_B	=>	1);
use constant (OFF	=>	0);
use constant (ON	=>	1);
use constant (HIGH	=>	0);
use constant (LOW	=>	1);
use constant (EL	=>	2);
use constant (CLOSED	=>	0);
use constant (OPEN	=>	1);
use constant (HALF	=>	0);
use constant (FULL	=>	1);
use constant (AIR	=>	1);
use constant (VHF_A	=>	2);
use constant (VHF_B	=>	3);
use constant (UHF	=>	6);
use constant (KEY	=>	1);
use constant (KEY_DATA	=>	2);
use constant (ALL	=>	3);
use constant (TIME	=>	0);
use constant (CARRIER	=>	1);
use constant (SEEK	=>	2);
use constant (DATA	=>	0);
use constant (BOTH	=>	1);
use constant (SLOW	=>	0);
use constant (FAST	=>	1);
use constant (APO_30	=>	1);
use constant (APO_60	=>	2);
use constant (FM		=>	0);
use constant (AM		=>	1);
use constant (ENGLISH	=>	0);
use constant (METRIC	=>	1);
use constant (MANUAL	=>	0);
use constant (PTT		=>	1);
use constant (AUTO		=>	2);
use constant (BLACK		=>	0);
use constant (BLUE		=>	1);
use constant (RED		=>	2);
use constant (MAGENTA		=>	3);
use constant (GREEN		=>	4);
use constant (CYAN		=>	5);
use constant (YELLOW		=>	6);
use constant (WHITE		=>	7);
use constant (TONES		=>	1,3..39);
use constant (NMEA		=>	1);
use constant (VFO		=>	0);
use constant (MEMORY	=>	2);
use constant (CALL		=>	3);
use constant (POSITIVE		=>	2);
use constant (NEGATIVE		=>	1);

sub NOCALLBACK {
	\&NOCALLBACK;
}

my %STEPS = (
	5		=>	0,
	6.25	=>	1,
	10		=>	2,
	12.5	=>	3,
	15		=>	4,
	20		=>	5,
	25		=>	6,
	30		=>	7,
	50		=>	8,
	100		=>	9
);
my %REV_STEPS;
$REV_STEPS{values %STEPS} = keys %STEPS;

my %TONES = (
	67		=>	1,
	71.9	=>	3,
	74.4	=>	4,
	77		=>	5,
	79.7	=>	6,
	82.5	=>	7,
	85.4	=>	8,
	88.5	=>	9,
	91.5	=>	10,
	94.8	=>	11,
	97.4	=>	12,
	100		=>	13,
	103.5	=>	14,
	107.2	=>	15,
	110.9	=>	16,
	114.8	=>	17,
	118.8	=>	18,
	123		=>	19,
	127.3	=>	20,
	131.8	=>	21,
	136.5	=>	22,
	141.3	=>	23,
	146.2	=>	24,
	151.4	=>	25,
	156.7	=>	26,
	162.2	=>	27,
	167.9	=>	28,
	173.8	=>	29,
	179.9	=>	30,
	186.2	=>	31,
	192.8	=>	32,
	203.5	=>	33,
	210.7	=>	34,
	218.8	=>	35,
	225.7	=>	36,
	223.6	=>	37,
	241.8	=>	38,
	250.3	=>	39
);
my %REV_TONES;
$REV_TONES{values %TONES} = keys %TONES;

my $DEBUG = 1;
my $TEXT = 1;

# Method error messages
use constant (INVALID_BAND	=>	
	"Invalid band selection, expected BAND_A or BAND_B (0/1)");
use constant (INVALID_ONOFF	=>
	"Invalid setting, expected OFF or ON (0/1)");
use constant (NOWRITE	=>
	"Too many arguments (read-only method)");
use constant (INVALID_MODE	=>
	"Invalid mode selection, expected FM or AM (0/1)");
use constant (INVALID_TONE	=>
	"Invalid tone selection, expected 1,3..39 (use ToTone method?)");
use constant (INVALID_COLOR	=>
	"Invalid color selection, expected 0..7 (use color constants?)");

sub new {
  my $caller = shift;
  my $serial = shift;

  my $self = {};
  
  my $UNIX = 0;
  my $WINDOWS = 1;

  my $os = ($^O eq "MSWin32" ? $WINDOWS : $UNIX);

  if ($os == $UNIX) {
		my $tty = $serial;
		$tty =~ s/[^\w\/\.]//g;
		if ($tty) {
			if ((-r $tty) && (-w $tty)) {
				system("stty 9600 -echo -cstopb raw < $tty");
				$self->{_fd} = gensym;
				if (open($self->{_fd}, "+<$tty")) {
					$self->{_serial} = $tty;
				} else {
					croak "$tty: $!";
				}
				my $oldfh = select($self->{_fd});
				$|=1;
				select($oldfh);
			} else {
				$! = 13;	# EACCES
			}
		}
  } elsif ($os == $WINDOWS) {
    my $configuration = $serial;
    require Win32::SerialPort;
    tie(*FH, 'Win32::SerialPort', $configuration) || croak("Can't tie: $^E");
    $self->{_fd} = *FH;
    $self->{_serial} = $configuration;
  }

  $self->{_CALLBACK} = {};
  $self->{_TEXT} = $TEXT;

  if ((!$serial) || $self->{_serial}) {
    bless $self, $caller;
    return $self;
  } else {
    return undef;
  }
}

##################
# Sends the raw argument straight to the serial port
sub Send {
	my $self = shift;
	my $data = shift;
	local($_);

	if ($DEBUG) {
		my $ddata = $data;
		chop($ddata);
		$ddata =~ s/[^\w\s]/./g;
		print "[Debug] Sending:  $ddata [";
		print join(" ", map(sprintf("%02x", ord($_)), split(//, $data)));
		print "]\n";
	}

	if ($self->{_TEXT}) {
		my $S = $self->{_fd};
		print $S $data;
	} else {
		syswrite($self->{_fd}, $data, length($data));
	}
}
sub RawSend {
	&Send(@_);
}

##################
# Receives raw data from the serial port.
sub RawReceive {
	my $self = shift;
	my $timeout = shift || 0.3;
	my $buf = "";

	if ($self->{_TEXT}) {
		my $save = $/;
		$/ = "\r";
		my $S = $self->{_fd};
		$buf = <$S>;
		$/ = $save;
	} else {
		my ($rin, $rout, $t);
		vec($rin, fileno($self->{_fd}), 1) = 1;
		while (select($rout=$rin, undef, undef, $timeout)) {
			sysread($self->{_fd}, $t, 1);
			$buf .= $t;
		}
	}

	if ($DEBUG) {
		my $ddata = $buf;
		chop($ddata);
		$ddata =~ s/[^\w\s]/./g;
		print "[Debug] Received: $ddata [";
		print join(" ", map(sprintf("%02x", ord($_)), split(//, $buf)));
		print "]\n";
	}

	return $buf;
}

##################
# Performs an action and returns the results
sub Do {
	my $self = shift;
	my $message = shift;
	my $args = shift;
	$args = " $args" if defined($args);
	$args .= join(",", @_);

	my $success = $self->Send("$message$args\r");

	if ($success) {
		my $result = $self->RawReceive($self->{Timeout} ? $self->{Timeout} : 0.3);

		chomp($result);
		return wantarray ? () : undef if $result eq "N";
		$self->do_poll($result) if $self->{_PollOnResult};

		$result =~ s/^\S+\s*//;

		return wantarray ? split(/,/, $result) : $result;
	} else {
		return wantarray ? () : undef;
	}
}

##################
# Enters binary mode for sending/receiving data
sub BinaryMode {
	my $self = shift;
	my $onoff = shift;

	&validate($onoff, INVALID_ONOFF, undef, ON, OFF);

	$self->{_TEXT} = (!$onoff) if defined($onoff);
	return $self->{_TEXT};
}

sub GetSocket {
	my $self = shift;

	return $self->{_fd};
}

# Checks the values of an argument to be sure it's within a required range
sub validate {
	my $what = shift;
	my $message = shift || "Invalid argument '$what'";

	for my $v (@_) {
		return 1 if $v eq $what;
	}

	if (defined($what)) {
		croak $message;
	} else {
		croak "Insufficient arguments";
	}
}

##################
# Waits $timeout seconds (or indefinitely if undef'd) for a notification
# from the D7 about an event.  It then passes that event off to any
# defined callback function and returns.
# Returns: undef=timed out, 0=no callback function, 1=callback called
# If called in a list context, the actual line received is returned as
# the second argument.
sub Poll {
	my $self = shift;
	my $timeout = shift;

	# AI must be ON for polling to do anything useful
	$self->AI(ON) unless $self->{_AI};

	my ($rin, $rout, $t, $buf);
	vec($rin, fileno($self->{_fd}), 1) = 1;
	while (select($rout=$rin, undef, undef, $timeout)) {
		sysread($self->{_fd}, $t, 1);
		$buf .= $t;
		if ($t eq "\r") {
			if ($DEBUG) {
				my $ddata = $buf;
				chop($ddata);
				$ddata =~ s/[^\w\s]/./g;
				print "[Debug] Received: $ddata [";
				print join(" ", map(sprintf("%02x", ord($_)), split(//, $buf)));
				print "]\n";
			}
			chop($buf);
			return $self->do_poll($buf);
		}
	}
	return undef;
}

##################
# Used by Poll and RawReceive to check incoming text to see if we should 
# pass it off to a callback function
sub do_poll {
	my $self = shift;
	my $buf = shift;

	my ($cmd, $args) = ($buf =~ /^(\S+)\s*(.*)/);

	# Quick hack to make TC callbacks work -- TS is not a real command?
	$cmd = "TC" if $cmd eq "TS";

	my @args = split(/,/, $args);
	if (exists($self->{_CALLBACK}->{$cmd})) {
		&{$self->{_CALLBACK}->{$cmd}}($self, $cmd, split(/,/,$args));
		return wantarray ? (1, $cmd, @args) : 1;
	} elsif (exists($self->{_CALLBACK}->{_DEFAULT_})) {
		&{$self->{_CALLBACK}->{_DEFAULT_}}($self, $cmd, split(/,/,$args));
		return wantarray ? (0, $cmd, @args) : 1;
	} else {
		return wantarray ? (0, $cmd, @args) : 0;
	}
}

##################
# Adds a coderef to the callback hash for the specified command
sub add_callback {
	my $self = shift;
	my $which = shift;
	my $proc = shift;

	undef $proc if $proc == NOCALLBACK;

	if (defined($proc)) {
		$self->{_CALLBACK}->{$which} = $proc;
	} else {
		delete $self->{_CALLBACK}->{$which};
	}
}

##################
# Sets the "default" callback function, where unassigned callback events go.
sub Callback {
	my $self = shift;
	my $proc = shift;

	return $self->add_callback("_DEFAULT_", $proc) if 
		(ref($proc) eq "CODE" || (!defined($proc)));
	croak "Not a code ref to Callback method";
}

##################
# Changes the PollOnResult flag.  If set, callback functions will be
# called for arguments returned from explicitely sent commands instead
# of just when things on the D7 change.
sub PollOnResult {
	my $self = shift;
	my $setting = shift;

	&validate($setting, INVALID_ONOFF, undef, ON, OFF);

	$self->{_PollOnResult} = $setting if defined($setting);
	return $self->{_PollOnResult};
}

##################
sub Simple_OnOff {
	my $item = shift;
	my $self = shift;
	my $setting = shift;

	return $self->add_callback($item, $setting) if ref($setting) eq "CODE";
	&validate($setting, INVALID_ONOFF, undef, ON, OFF);

	$self->Do($item, $setting);
}

sub Simple_Text {
	my $item = shift;
	my $self = shift;
	my $text = shift;

	return $self->add_callback($item, $text) if ref($text) eq "CODE";

	$self->Do($item, $text);
}

sub Unknown {
	my $item = shift;
	my $self = shift;

	if ($^W) {
		carp("Warning, $item is an unknown/undefined D7 function in THD7.pm version $VERSION");
	}
	return $self->add_callback($item, $_[0]) if ref($_[0]) eq "CODE";

	$self->Do($item, @_);
}

sub ToStep {
	my ($self, $step) = @_;
	$step = $self unless ref($self);
	return $STEPS{$step};
}
sub FromStep {
	my ($self, $step) = @_;
	$step = $self unless ref($self);
	return $REV_STEPS{$step};
}
sub ToTone {
	my ($self, $tone) = @_;
	$tone = $self unless ref($self);
	return $TONES{$tone};
}
sub FromTone {
	my ($self, $tone) = @_;
	$tone = $self unless ref($self);
	return $REV_TONES{$tone};
}
sub ToPosit {
	my $self = shift;
	unshift(@_, $self) unless ref($self);
	my $latm = shift;
	my $lats = shift;
	my $longm = shift;
	my $longs = shift;
	my ($ns, $ew);

	if ($latm < 0) {
		$ns = 1;
		$latm *= -1;
	} else {
		$ns = 0;
	}

	if ($longm < 0) {
		$ew = 1;
		$longm *= -1;
	} else {
		$ew = 0;
	}

	my $posit = sprintf("%02d%05d%1d%03d%05d%1d", $latm, $lats * 1000,
		$ns, $longm, $longs * 1000, $ew);

	if ($DEBUG) {
		print "[DEBUG] $latm' $lats\" $ns x $longm' $longs\" $ew -> $posit\n";
	}
	return $posit;
}
sub FromPosit {
	my $self = shift;
	unshift(@_, $self) unless ref($self);
	my $posit = shift;

	my $latm = substr($posit, 0, 2);
	my $lats = substr($posit, 2, 5) / 1000;
	my $ns = substr($posit, 7, 1);
	my $longm = substr($posit, 8, 3);
	my $longs = substr($posit, 11, 5) / 1000;
	my $ew = substr($posit, 16, 1);

	$latm *= -1 if $ns;
	$longm *= -1 if $ew;

	return ($latm, $lats, $longm, $longs);
}

# Begin TH-D7 Functions

##################
# Advanced output
#
# Syntax:
# AI [0|1]
# AI [OFF|ON]
#
# Turns on output functions. Immediate functions output to the serial port.  
# This feature must be enabled before polling for events.
#
sub AI {
	my $self = shift;
	my $which = shift;

	return $self->add_callback("AI", $which) if ref($which) eq "CODE";
	&validate($which, INVALID_ONOFF, undef, ON, OFF);

	$self->{_AI} = $self->Do("AI", $which);
}

##################
# Advanced Intercept Point
#
# Syntax:
# AIP [0|1] 
# AIP [OFF|ON]
#
# Alias: VHFAIP
#
sub AIP {
	&Simple_OnOff("AIP", @_);
}
sub VHFAIP { &AIP(@_); }

##################
# Automatic Message Reply
#
# Syntax:
# AMR [0|1] 
# AMR [OFF|ON]
#
sub AMR {
	my $self = shift;
	my $mode = shift;

	return $self->add_callback("AMR", $mode) if ref($mode) eq "CODE";
	# &validate($mode, ...);

	$self->Do("AMR", $mode);
}

##################
# Send APRS message
#
# Syntax: AMGS [Callsign][Message] 
#
# Alias: APRS_Send
#
sub AMSG {
  my $self = shift;
  my $callsign = shift;
  my $message = shift;

	return $self->add_callback("AMSG", $message) if ref($message) eq "CODE";
  # Both parameters are strings so validation step has been left out.
  
  $self->Do("AMSG", 0, $callsign, $message);
}
sub APRS_Send { &AMSG(@_); }

##################
# Automatic Power Off
#
# APO [0..2] 
# APO [OFF|APO_30|APO_60] 
#
# This subroutine returns a second argument that, when ON, indicates the unit is 
# about to power off due to inactivity.
#
sub APO {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("APO", $setting) if ref($setting) eq "CODE";
	&validate($setting, 
		"Invalid APO setting, expected OFF/APO_30/APO_60 [0..2]", undef, OFF,
		APO_30, APO_60);

	$self->Do("APO", $setting);
}

##################
# Auto Repeater Offset
# 
# Syntax:
# ARO [0|1]
# ARO [OFF|ON]
#
# Alias: AutoOffset
#
sub ARO {
	&Simple_OnOff("ARO", @_);
}
sub AutoOffset { &ARO(@_); }

##################
# APRS Position Limit
#
# Syntax: ARL n (units dependent upon UNIT setting)
# Alias: APRS_PosLimit
#
sub ARL {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("ARL", $setting) if ref($setting) eq "CODE";

	$setting = sprintf("%04d", $setting) if defined($setting);
	$self->Do("ARL", $setting);
}
sub APRS_PosLimit { &ARL(@_); }

##################
# Speaker Balance
#
# Syntax: BAL [0|1],[0..4], 0=A Only, 4=B Only, 2=Even
#
# Alias: Balance
#
# Returns: Balance [0..4]
#
sub BAL {
	my $self = shift;
	my $balance = shift;

	return $self->add_callback("BAL", $balance) if ref($balance) eq "CODE";
	&validate($balance, "Invalid balance setting (0..4)", undef, 0..4);

	$self->Do("BAL", $balance);
}
sub Balance { &BAL(@_); }

##################
# Band Switch
#
# Syntax:
# BC [0|1]
# BC [A|B]
# Alias: Band
#
# Returns: Band A/B [0|1]
#
sub BC {
	my $self = shift;
	my $which = shift;

	return $self->add_callback("BC", $which) if ref($which) eq "CODE";
	&validate($which, INVALID_BAND, undef, BAND_A, BAND_B);

	$self->Do("BC", $which);
}
sub Band { &BC(@_); }

##################
# APRS Beacon
#
# Syntax: 
# BCN [0|1]
# BCN [OFF|ON]
#
# Alias: APRS_Beacon
#
sub BCN {
	&Simple_OnOff("BCN", @_);
}
sub APRS_Beacon { &BCN(@_); }

##################
# Bell
#
# Syntax: 
# BEL [0|1],[0|1]
# BEL [A|B],[OFF|ON]
# Alias: Bell
#
# Turn bell on or off for band A or band B
#
sub BEL {
	my $self = shift;
	my $band = shift;
	my $setting = shift;

	return $self->add_callback("BEL", $band) if ref($band) eq "CODE";
	&validate($band, INVALID_BAND, BAND_A, BAND_B);
	&validate($setting, INVALID_ONOFF, undef, ON, OFF);

	my $arg = $band;	
	$arg = "$band,$setting" if defined($setting);

	$self->Do("BEL", $arg);
}
sub Bell { &BEL(@_); }

##################
# Key Beep Mode
#
# Syntax:
# BEP [0..3]
# BEP [OFF|KEY|KEY_DATA|ALL]
# Alias: Beep
#
sub BEP {
	my $self = shift;
	my $mode = shift;

	return $self->add_callback("BEP", $mode) if ref($mode) eq "CODE";
	&validate($mode, "Invalid beep setting, expected 0..3", undef, 0..3);

	$self->Do("BEP", $mode);
}
sub Beep { &BEP(@_); }

##################
# APRS Tone Alert Events
# 
# Syntax: BEPT [0..3] 
#
# Sets a distinct tone alert for APRS events.
#
sub BEPT {
  my $self = shift;
  my $mode = shift;
  
  return $self->add_callback("BEPT", $mode) if ref($mode) eq "CODE";
	&validate($mode, "Invalid APRS beep setting, expected 0..3", undef, 0..3);

  $self->Do("BEPT", $mode);
}

##################
# Store VHO Frequency
#
# Syntax: BUF [A|B],freq_in_Hz,step,?,rev,tone,ctcss,?,tonefreq,?,ctcssfreq,ofs,mode
# Alias: Buffer, Set
#
# Sets the VFO frequency for band [A|B] to the parameters specified.
#
sub BUF {
	my $self = shift;
	my ($band, $freq, $step, $x1, $reverse, $tone, $ctcss, $x2,
		$tonefreq, $x3, $ctcssfreq, $offset, $mode) = @_;

	return $self->add_callback("BUF", $band) if ref($band) eq "CODE";
	&validate($band, INVALID_BAND, BAND_A, BAND_B);
	if ($freq) {
		croak("Invalid frequency, expected integer Hz") if $freq !~ /^\d+$/;
		&validate($step, "Invalid step range, expected 0..9", 0..9);
		&validate($reverse, INVALID_ONOFF, ON, OFF);
		&validate($tone, INVALID_ONOFF, ON, OFF);
		&validate($ctcss, INVALID_ONOFF, ON, OFF);
		&validate($tonefreq, "Invalid PL freq, expected 1,3..39 (use ToTone method?)", TONES);
		&validate($ctcssfreq, "Invalid CTCSS freq, expected 1,3..39 (use ToTone method?)", TONES);
		croak("Invalid repeater offset, expected integer Hz") if $offset !~ /^\d+$/;
		&validate($mode, INVALID_MODE, FM, AM);
		$self->Do("BUF", $band, sprintf("%011d", $freq), $step, $x1 ? $x1 : 0,
			$reverse, $tone, $ctcss, $x2 ? $x2 : 0, $tonefreq, $x3 ? $x3 : 0,
			$ctcssfreq, sprintf("%011d", $offset), $mode);
	} else {
		$self->Do("BUF", $band);
	}
}
sub Buffer { &BUF(@_); }
sub Set { &BUF(@_); }

##################
# Squlech on Band (Not Writeable)
#
# Syntax: 
# BY [0|1],[0|1]
# BY [A|B], [CLOSED|OPEN]
# Alias: Squelched
#
# Returns: Band A/B [0|1], Squelch Open [0|1]
#
sub BY {
	my $self = shift;
	my $band = shift;
	my $anything_else = shift;

	return $self->add_callback("BY", $band) if ref($band) eq "CODE";
	&validate($band, INVALID_BAND, BAND_A, BAND_B);
	&validate($anything_else, NOWRITE, undef);

	$self->Do("BY", $band);
}
sub Squelched { &BY(@_); }

##################
# Channel Display Mode
# 
# Syntax: CH [0|1] 
# Alias: ChannelMode
#
# Channel Display mode, access restricted to navigating the stored memory channels ONLY.
#
sub CH {
	&Simple_OnOff("CH", @_);
}
sub ChannelMode { &CH(@_); }

##################
# LCD Screen Constrast
#
# Syntax: CNT [1-16] LCD contrast (8 = default)
# Alias: Contrast
#
sub CNT {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("CNT", $setting) if ref($setting) eq "CODE";
	&validate($setting, "Invalid contrast setting, expected 1..16", undef,
		1..16);

	if (defined($setting)) {
		$self->Do("CNT", sprintf("%02d", $setting));
	} else {
		$self->Do("CNT");
	}
}
sub Contrast { &CNT(@_); }

##################
# CTCSS Enabled
#
# Syntax: 
# CT [0|1] 
# CTCSS [OFF|ON]
# Alias: CTCSS
#
sub CT {
	&Simple_OnOff("CT", @_);
}
sub CTCSS { &CT(@_); }

##################
# CTCSS Frequency
#
# Syntax: CTN n 
# Alias: CTCSSFreq
#
sub CTN {
	my $self = shift;
	my $freq = shift;

	return $self->add_callback("CTN", $freq) if ref($freq) eq "CODE";
	&validate($freq, "Invalid CTCSS frequency, expected 1,3..39 (use ToTone method?)",
    undef, TONES);

	$self->Do("CTN", $freq);
}
sub CTCSSFreq { &CTN(@_); }

##################
# Dual Channels
#
# Syntax: DL [OFF|ON]
# Alias: Dual
#
# Returns: Setting OFF/ON [0|1]
#
sub DL {
	&Simple_OnOff("DL", @_);
}
sub Dual { &DL(@_); }

##################
# DTMF Store Sequence in Memory
#
# Syntax: DM cc,n (store sequence n in memory cc)
# Alias: DTMF_Memory
#
sub DM {
	my $self = shift;
	my $mem = shift;
	my $num = shift;

	return $self->add_callback("DM", $mem) if ref($mem) eq "CODE";
	croak "Invalid DTMF memory number, expected integer" unless $mem =~ /^\d+$/;

	$self->Do("DM", sprintf("%02d", $mem), $num);	
}
sub DTMF_Memory { &DM(@_); }

##################
# DTMF Names Channel
# 
# Syntax: DMN cc,name
# Alias: DTMF_Name
#
sub DMN {
	my $self = shift;
	my $mem = shift;
	my $name = shift;

	return $self->add_callback("DMN", $mem) if ref($mem) eq "CODE";
	croak "Invalid DTMF memory number, expected integer" unless $mem =~ /^\d+$/;

	$self->Do("DMN", sprintf("%02d", $mem), $name);
}
sub DTMF_Name { &DMN(@_); }

##################
# DCD Sense
# 
# Syntax: 
# DS [0|1]
# DS [DATA|BOTH]
# Alias: DCDSense
#
sub DS {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("DS", $setting) if ref($setting) eq "CODE";
	&validate($setting, "Invalid DS setting, expected DATA/BOTH [0|1]", 
		undef, DATA, BOTH);

	$self->Do("DS", $setting);
}
sub DCDSense { &DS(@_); }

##################
# Set Data BAnd
#
# Syntax: 
# DTB [0|1] 
# DTB [A|B]
# Alias: DataBand
#
sub DTB {
	&Simple_OnOff("DTB", @_);
}
sub DataBand { &DTB(@_); }

##################
# APRS Data Tx Mode
#
# Syntax: 
# DTX [0..2]
# DTX [MANUAL|PTT|AUTO]
# Alias: APRS_TransmitMode
#
sub DTX {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("DTX", $setting) if ref($setting) eq "CODE";
	&validate($setting, "Invalid APRS TX mode, expected MANUAL/PTT/AUTO [0..2]",
		undef, MANUAL, PTT, AUTO);

	$self->Do("DTX", $setting);
}
sub APRS_TransmitMode { &DTX(@_); }

##################
# Set Full Duplex Mode
#
# Syntax: 
# DUP [0|1] 
# DUP [HALF|FULL]
# Alias: Duplex
#
sub DUP {
	&Simple_OnOff("DUP", @_);
}
sub Duplex { &DUP(@_); }

##################
# Adjust Frequency Downward
#
# Syntax: DW
# Alias: Down
#
sub DW {
	my $self = shift;
	my $blah = shift;

	return $self->add_callback("DW", $blah) if ref($blah) eq "CODE";
	&validate($blah, NOWRITE, undef);

	$self->Do("DW");
}
sub Down { &DW(@_); }

##################
# Tune Enable
#
# Syntax:
# ELK [0|1]
# ELK [OFF|ON]
# Alias: TuneEnable
#
sub ELK {
	&Simple_OnOff("ELK", @_);
}
sub TuneEnable { &ELK(@_); }

##################
# Returns an Even Numbered List of Band Extents
#
# Syntax: FL
# Alias: FreqList
#
sub FL {
	my $self = shift;
	my $blah = shift;

	return $self->add_callback("FL", $blah) if ref($blah) eq "CODE";
	&validate($blah, NOWRITE, undef);

	$self->Do("FL");
}
sub FreqList { &FL(@_); }

##################
# Sets the Current Frequency and Select Band
#
# Syntax: FQ
# Alias: Freq
#
# Sets/returns the current frequency and step on the currently selected band.  
# This callback is not normally used.
#
sub FQ {
	my $self = shift;
	my $freq = shift;
	my $step = shift;

	return $self->add_callback("FQ", $freq) if ref($freq) eq "CODE";
	if (defined($freq)) {
		croak("Invalid frequency, expected integer Hz") unless $freq =~ /^\d+$/;
		&validate($step, "Invalid step, expected 0..9 (use ToStep method?)", 
			0..9);
		$freq .= ",$step";
	}

	$self->Do("FQ", $freq);
}

##################
# GPS Unit
# 
# Syntax:
# GU [0|1] 
# GU [OFF|ON]
# Alias: GPS
#
sub GU {
	&Simple_OnOff("GU", @_);
}
sub GPS { &GU(@_); }

##################
# Set APRS Icon
#
# Syntax:
# ICO [0|1],i 
# ICO [BUILT-IN|EXTENDED], icon # or string
# Alias: APRS_Icon
#
sub ICO {
	my $self = shift;
	my $extended = shift;
	my $icon = shift;

	return $self->add_callback("ICO", $extended) if ref($extended) eq "CODE";
	&validate($extended, "Invalid icon description flag, expected 1 or 0",
		undef, 1, 0);
	if ($extended) {
		croak "Invalid APRS icon, expected user-defined two-byte icon string"
			unless $icon;
	} elsif (defined($extended)) {
		&validate($icon, "Invalid APRS icon, expected built-in hex range 0..E",
			 0..9, "A".."E", "a".."e");
	}

	$self->Do("ICO", $extended, $icon);
}
sub APRS_Icon { &ICO(@_); }

##################
# Radio ID
# 
# Syntax: ID
#
# Returns ID (should be "TH-D7")
#
sub ID {
	my $self = shift;
	my $callback = shift;

	return $self->add_callback("ID", $callback) if ref($callback) eq "CODE";

	$self->Do("ID");
}

##################
# Lock Radio
#
# Syntax:
# LK [0|1]
# LK [OFF|ON]
# Alias: Lock
#
sub LK {
	&Simple_OnOff("LK", @_);
}
sub Lock { &LK(@_); }

##################
# Radio Lamp
#
# Syntax: 
# LMP [0|1]
# LMP [OFF|ON]
# Alias: Lamp
#
sub LMP {
	&Simple_OnOff("LMP", @_);
}
sub Lamp { &LMP(@_); }

##################
# APRS list message
#
# Syntax: LIST
# Alias: APRS_List
#
sub LIST {
	my $self = shift;
	my $message = shift;

	return $self->add_callback("LIST", $message) if ref($message) eq "CODE";
	&validate($message, "Invalid message id", undef, 1..40);

	$self->Do("LIST", $message, ". KB8VME");
}
sub APRS_List { &LIST(@_); }

##################
# MAC Color SSTV
# 
# Syntax: MAC color
# Alias: SSTV_CallColor
#
sub MAC {
	my $self = shift;
	my $color = shift;

	return $self->add_callback("MAC", $color) if ref($color) eq "CODE";
	&validate($color, INVALID_COLOR, undef, 0..7);

	$self->Do("MAC", $color);
}
sub SSTV_CallColor { &MAC(@_); }

##################
# Set Memory Channel
#
# Syntax: 
# MC [0|1], n
# MC [BAND_A|BAND_B], n
# Alias: Memory
#
sub MC {
	my $self = shift;
	my $band = shift;
	my $mem = shift;

	return $self->add_callback("MC", $band) if ref($band) eq "CODE";
	&validate($band, INVALID_BAND, BAND_A, BAND_B);

	$self->Do("MC", $band, $mem);
}
sub Memory { &MC(@_); }

##################
# Modulation Mode
#
# Syntax: 
# MD [0|1] 
# MD [FM|AM]
# Alias: Modulation
#
sub MD {
	my $self = shift;
	my $amfm = shift;

	return $self->add_callback("MD", $amfm) if ref($amfm) eq "CODE";
	&validate($amfm, "Invalid modulation, expected AM or FM", undef, AM, FM);

	$self->Do("MD", $amfm);
}
sub Modulation { &MD(@_); }

##################
# Lock Memory Channel
#
# Syntax: 
# MCL [0|1],[0|1] 
# MCL [BAND_A|BAND_B] [OFF|ON]
# Alias: MemoryLock
#
sub MCL {
	my $self = shift;
	my $band = shift;
	my $locked = shift;

	return $self->add_callback("MCL", $band) if ref($band) eq "CODE";
	&validate($locked, INVALID_ONOFF, undef, ON, OFF);

	$self->Do("MCL", $band, $locked);
}
sub MemoryLock { &MCL(@_); }

##################
# Power-on Message
#
# Syntax: MES message
# Alias: Message
#
sub MES {
	&Simple_Text("MES", @_);
}
sub Message { &MES(@_); }

##################
# Memory Channel Name
#
# Syntax: MNA 0?,n,name (8chars max)
# Alias: MemoryName
#
sub MNA {
	my $self = shift;
	my $x1 = shift;
	my $mem = shift;
	my $name = shift;

	return $self->add_callback("MNA", $x1) if ref($x1) eq "CODE";
	$x1 = 0 unless $x1;
	$mem = 0 unless $mem;

	$self->Do("MNA", $x1, $mem, $name);
}
sub MemoryName { &MNA(@_); }

##################
# Monitor Mode
#
# Syntax: MON [0|1] 
# Alias: Monitor
#
# Turns on/off "monitor" (squelch).  Similar in effect to BY, but uses 
# the currently selected band.
#
sub MON {
	&Simple_OnOff("MON", @_);
}
sub Monitor { &MON(@_); }

##################
# Position
#
# Syntax: MP posit (iiffffNiiiffffW)
#
# Use ToPosit method to convert normalized coordinates to this format.
# Alias: Position
#
sub MP {
	my $self = shift;
	my $position = shift;

	return $self->add_callback("MP", $position) if ref($position) eq "CODE";
	croak "Invalid position string (use ToPosit?)"
		unless !defined($position) || $position =~ /^\d{15}$/;

	$self->Do("MP", $position);
}
sub Position { &MP(@_); }

##################
# Read Memory Channel
#
# Syntax: MR 0?,0?,n Reads memory channel n
# This appears to be the only way you can get an "MR" response, so callback 
# seems unnecessary
# Alias: MemoryRead
#
sub MR {
	my $self = shift;
	my $x1 = shift;
	my $x2 = shift;
	my $mem = shift;

	return $self->add_callback("MR", $x1) if ref($x1) eq "CODE";
	$x1 = 0 unless $x1;
	$x2 = 0 unless $x2;
	croak "Invalid memory channel, expected integer" unless $mem =~ /^\d+$/;

	$self->Do("MR", $x1, $x2, sprintf("%03d", $mem));
}
sub MemoryRead { &MR(@_); }

##################
# Memory Write
#
# Syntax: MW 0?,n,freq,step,0?,rev,tone,ctcss,0?,tonefreq,0?,ctcssfreq,ofs,mode,0?
# Alias: MemoryWrite
#
sub MW {
	my $self = shift;
	my ($x1, $mem, $freq, $step, $x2, $reverse, $tone, $ctcss, $x3,
		$tonefreq, $x4, $ctcssfreq, $offset, $mode, $x5) = @_;

	return $self->add_callback("MW", $x1) if ref($x1) eq "CODE";
	if ($freq) {
		croak("Invalid frequency, expected integer Hz") if $freq !~ /^\d+$/;
		&validate($step, "Invalid step range, expected 0..9 (use ToStep method?)",
      0..9);
		&validate($reverse, INVALID_ONOFF, ON, OFF);
		&validate($tone, INVALID_ONOFF, ON, OFF);
		&validate($ctcss, INVALID_ONOFF, ON, OFF);
		&validate($tonefreq, "Invalid PL freq, expected 1,3..39 (use ToTone method?)",
      TONES);
		&validate($ctcssfreq, "Invalid CTCSS freq, expected 1,3..39 (use ToTone method?)",
      TONES);
		croak("Invalid repeater offset, expected integer Hz") if $offset !~ /^\d+$/;
		&validate($mode, INVALID_MODE, FM, AM);
		$self->Do("MW", $x1 ? $x1 : 0, sprintf("%03d", $mem), 
			sprintf("%011d", $freq), $step, $x2 ? $x2 : 0,
			$reverse, $tone, $ctcss, $x3 ? $x3 : 0, $tonefreq, $x4 ? $x4 : 0,
			$ctcssfreq, sprintf("%011d", $offset), $mode, $x5 ? $x5 : 0);
	} else {
		$self->Do("MW", $x1, $mem);
	}
}
sub MemoryWrite { &MW(@_); }

##################
# Call
#
# Syntax: MYC call
# Alias: APRS_MyCall
#
sub MYC {
	&Simple_Text("MYC", @_);
}
sub APRS_MyCall { &MYC(@_); }

##################
# NSFT 
#
sub NSFT {
	my $self = shift;
	my $x1 = shift;

	return $self->add_callback("NSFT", $x1) if ref($x1) eq "CODE";

	$self->Do("NSFT", $x1, @_);
}

##################
# Repeater Offset
#
# Syntax: OS nnnnnnnnn 
# Alias: Offset
#
# Note, repeater offset is in Hz
#
sub OS {
	my $self = shift;
	my $offset = shift;

	return $self->add_callback("OS", $offset) if ref($offset) eq "CODE";
	$offset = sprintf("%09d", $offset) if defined($offset);

	$self->Do("OS", $offset);
}
sub Offset { &OS(@_); }

##################
# APRS Position Comment
#
# Syntax: 
# POSC [0..7]
# POSC off duty|enroute|in service|returning|committed|special|priority|emergency
# Alias: APRS_Comment
#
sub POSC {
	my $self = shift;
	my $comment = shift;

	return $self->add_callback("POSC", $comment) if ref($comment) eq "CODE";
	&validate($comment, "Invalid comment setting, expected 0..9", undef, 0..9);

	$self->Do("POSC", $comment);
}
sub APRS_Comment { &POSC(@_); }

##################
# APRS Packet Path
# Syntax: PP path 
# Alias: APRS_Path
#
sub PP {
	&Simple_Text("PP", @_);
}
sub APRS_Path { &PP(@_); }

##################
# DTMF Transmit Pause
# 
# Syntax: 
# PT [0-6]
# PT 100|200|500|750|1000|1500|2000 ms
# Alias: DTMF_Pause
#
sub PT {
	my $self = shift;
	my $pause = shift;

	return $self->add_callback("PT", $pause) if ref($pause) eq "CODE";
	&validate($pause, "Invalid pause range, expected 0..6", undef, 0..6);

	$self->Do("PT", $pause);
}
sub DTMF_Pause { &PT(@_); }
	
##################
# Programmable VFO
# 
# Syntax: 
# PV [1|2|3|6],f1,f2 
# PV [AIR|VHF_A|VHF_B|UHF] low=f1 high=f2
# Alias: ProgrammableVFO
#
# f1 and f2 are frequencies in MHz.
#
sub PV {
	my $self = shift;
	my $band = shift;
	my $f1 = shift;
	my $f2 = shift;

	return $self->add_callback("PV", $band) if ref($band) eq "CODE";
	&validate($band, "Invalid PV band, expected AIR/VHF_A/VHF_B/UHF",
		AIR, VHF_A, VHF_B, UHF);
	if (defined($f1)) {
		if ($f1 =~ /\D/) {
			croak("Invalid PV argument, expected numeric MHz value for f1");
		} 
		if ($f2 =~ /\D/) {
			croak("Invalid PV argument, expected numeric MHz value for f2");
		} 
		$self->Do("PV", $band, sprintf("%05d,%05d", $f1, $f2));
	} else {
		$self->Do("PV", $band);
	}
}
sub ProgrammableVFO { &PV(@_); }

##################
# Reverse Mode
#
# Syntax: REV [OFF|ON]
# Alias: Reverse
#
# Returns: Setting OFF/ON [0|1]
#
sub REV {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("REV", $setting) if ref($setting) eq "CODE";
	&validate($setting, "Argument must be ON or OFF (1/0)", undef, ON, OFF);

	$self->Do("REV", $setting);
}
sub Reverse { &REV(@_); }

##################
# SSTV RSV Message
#
# Syntax: RSV message 
# Alias: SSTV_RSV
#
sub RSV {
	&Simple_Text("RSV", @_);
}
sub SSTV_RSVMessage { &RSV(@_); }

##################
# SSTV RSC Color
#
# Syntax: RSC color[0..7] 
# Alias: SSTV_RSVColor
#
sub RSC {
	my $self = shift;
	my $color = shift;

	return $self->add_callback("RSC", $color) if ref($color) eq "CODE";
	&validate($color, INVALID_COLOR, undef, 0..7);

	$self->Do("RSC", $color);
}
sub SSTV_RSVColor { &RSC(@_); }

##################
# RX Receive
#
# Syntax: RX
# Alias: Receive
#
# Returns: 1 if success, undef if failure
#
sub RX {
	my $self = shift;
	my $which = shift;

	return $self->add_callback("RX", $which) if ref($which) eq "CODE";
	&validate($which, NOWRITE, undef);

	return defined($self->Do("RX")) ? 1 : undef;
}
sub Receive { &RX(@_); }

##################
# Scan Toggle
# 
# Syntax:
# SC [0|1]
# SC [OFF|ON]
# Alias: Scan
#
# Begins/stops scanning on the currently selected band
#
sub SC {
	&Simple_OnOff("SC", @_);
}
sub Scan { &SC(@_); }

##################
# Sky Commander Call Sign
# 
# SCC call
# Alias: Sky_CommanderCall
#
sub SCC {
	&Simple_Text("SCC", @_);
}
sub Sky_CommanderCall { &SCC(@_); }

##################
# Scan Resume
#
# Syntax: 
# SCR [0..2]
# SCR [TIME|CARRIER|SEEK]
# Alias: ScanResume
#
sub SCR {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("SCR", $setting) if ref($setting) eq "CODE";
	&validate($setting, "Invalid SCR setting, expected 0..2", undef, 0..2);

	$self->Do("SCR", $setting);
}
sub ScanResume { &SCR(@_); }

##################
# Sky Command Transporter Call Sign
#
# Syntax: SCT call call sign
# Alias: Sky_TransporterCall
#
sub SCT {
	&Simple_Text("SCT", @_);
}
sub Sky_TransporterCall { &SCT(@_); }

##################
# Repeater Offset Shift
#
# Syntax: 
# SFT [0|1|2]
# SFT [OFF|NEGATIVE|POSITIVE]
# Alias: Shift
#
sub SFT {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("SFT", $setting) if ref($setting) eq "CODE";
	&validate($setting, "Invalid shift, expected OFF/NEGATIVE/POSITIVE",
		undef, OFF, NEGATIVE, POSITIVE);

	$self->Do("SFT", $setting);
}
sub Shift { &SFT(@_); }

##################
# Sky Commander Access Tone
# 
# Syntax: SKTN tone [1,3..39]
# Alias: Sky_Tone
#
sub SKTN {
	my $self = shift;
	my $tone = shift;

	return $self->add_callback("SKTN", $tone) if ref($tone) eq "CODE";
	&validate($tone, INVALID_TONE, undef, TONES);

	$self->Do("SKTN", $tone);
}
sub Sky_Tone { &SKTN(@_); }

##################
# Signal Meter
#
# Syntax: 
# SM [0|1],nn
# SM [A|B
# Alias: SignalMeter
#
# Returns 00..05, READ ONLY
#
sub SM {
	my $self = shift;
	my $band = shift;
	my $else = shift;

	return $self->add_callback("SM", $band) if ref($band) eq "CODE";
	&validate($band, INVALID_BAND, BAND_A, BAND_B);
	&validate($else, NOWRITE, undef);

	$self->Do("SM", $band);
}
sub SignalMeter { &SM(@_); }

##################
# SSTV Message Color
#
# Syntax: SMC color[0..7]
# Alias: SSTV_MessageColor
#
sub SMC {
	my $self = shift;
	my $color = shift;

	return $self->add_callback("SMC", $color) if ref($color) eq "CODE";
	&validate($color, INVALID_COLOR, undef, 0..7);
}
sub SSTV_MessageColor { &SMC(@_); }

##################
# SSTV Message
#
# Syntax: SMSG msg SSTV
# Alias: SSTV_Message
#
sub SMSG {
	&Simple_Text("SMSG", @_);
}
sub SSTV_Message { &SMSG(@_); }

##################
# SSTV Call
#
# SMY call
# Alias: SSTV_MyCall
#
sub SMY {
	&Simple_Text("SMY", @_);
}
sub SSTV_MyCall { &SMY(@_); }

##################
# Squelch
#
# Syntax: 
# SQ [0|1],[00..05]
# SQ [A|B] (00=open)
# Alias: Squelch
#
sub SQ {
	my $self = shift;
	my $band = shift;
	my $value = shift;

	return $self->add_callback("SQ", $band) if ref($band) eq "CODE";
	&validate($band, INVALID_BAND, BAND_A, BAND_B);
	&validate($value, "Invalid squelch setting, expected 0..5 (0=open)",
		undef, 0..5);

	$value = sprintf("%02d", $value) if defined($value);

	$self->Do("SQ", $band, $value);
}
sub Squelch { &SQ(@_); }

##################
# Set Step Size
#
# Syntax: ST n 
# Alias: Step
#
sub ST {
	my $self = shift;
	my $step = shift;

	return $self->add_callback("ST", $step) if ref($step) eq "CODE";
	&validate($step, "Invalid step size, expected 0..9 (use ToStep method?)",
		undef, 0..9);

	$self->Do("ST", $step);
}
sub Step { &ST(@_); }

##################
# Set APRS Text
#
# Syntax: STAT text
# Alias: APRS_Status
#
sub STAT {
	&Simple_Text("STAT", @_);
}
sub APRS_Status { &STAT(@_); }

##################
# APRS Status Tx
#
# Syntax: STXR
# Alias: APRS_StatusTx
#
sub STXR {
  my $self = shift;
  my $level = 1;

	return $self->add_callback("STXR", $level) if ref($level) eq "CODE";
	&validate($level, "Invalid statux tx, expected 0..8", undef, 0..8);

  $self->Do("STXR", $level);
}
sub APRS_StatusTx { &STXR(@_); }

##################
# SSTV Superimpose
#
# Syntax: STC call,n
# Alias: SSTV_Superimpose
#
sub STC {
	my $self = shift;
	my $call = shift;
	my $x1 = shift;

	return $self->add_callback("STC", $call) if ref($call) eq "CODE";

	$self->Do("STC", $call, $x1 ? $x1 : 0);
}
sub SSTV_Superimpose { &STC(@_); }

##################
# SSTV Transmit Mode
#
# Syntax: STS transmit mode
# Alias: SSTV_Mode
#
sub STS {
	my $self = shift;
	my $x1 = shift;

	return $self->add_callback("STS", $x1) if ref($x1) eq "CODE";

	$self->Do("STS", $x1, @_);
}
sub SSTV_Mode { &STS(@_); }

##################
# Set Battery Saver
#
# Syntax: 
# SV [0..9]
# SV (off|0.2|0.4|0.6|0.8|1.0|2|3|4|5)
# Alias: BatterySave
#
sub SV {
	my $self = shift;
	my $mode = shift;

	return $self->add_callback("SV", $mode) if ref($mode) eq "CODE";
	&validate($mode, "Invalid saver mode, expected 0..9", undef, 0..9);

	$self->Do("SV", $mode);
}
sub BatterySave { &SV(@_); }

##################
# TNC Packet Mode
#
# Syntax: 
# TC [0|1]
# TC [OFF|ON] WRITE-ONLY
# Alias: Packet
#
# Note: Entering packet mode via the D7 keypad will NOT activate a
# callback via this method.
# Note: While in Packet mode, NO OTHER COMMANDS WILL BE AVAILABLE
# EXCEPT THIS ONE.  I suppose if your script is designed for that
# sort of thing, you can use the RawSend and RawReceive methods to
# talk to the TNC directly.
# Note: The command itself actually takes 0=ON and 1=OFF, but we
# switch them in the code.
# Note: A callback will be sent ONLY upon the issue of a TC 1 while
# in packet mode, BUT, this callback uses the command "TS" for some
# strange reason.  I think we'll change it to TC in the callback
# code.
#
sub TC {
	my $self = shift;
	my $onoff = shift;

	return $self->add_callback("TS", $onoff) if ref($onoff) eq "CODE";
	&validate($onoff, INVALID_ONOFF, ON, OFF);

	$self->Do("TC", $onoff ? OFF : ON);
}
sub Packet { &TC(@_); }

##################
# Toggle APRS Mode
#
# Syntax: 
# TNC [0|1]
# TNC [OFF|ON]
#
# A notification will not be sent via this callback in the event the D7
# enters Packet mode.
# Alias: APRS
#
sub TNC {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("TNC", $setting) if ref($setting) eq "CODE";
	&validate($setting, INVALID_ONOFF, undef, ON, OFF);

	$self->Do("TNC", $setting);
}
sub APRS { &TNC(@_); }

##################
# PL Tone Enable
#
# Syntax: TO [0|1]
# Alias: Tone
#
sub TO {
	&Simple_OnOff("TO", @_);
}
sub Tone { &TO(@_); }

##################
# PL Tone Frequency
#
# Syntax: TN n
# Alias: ToneFreq
#
sub TN {
	my $self = shift;
	my $tone = shift;

	return $self->add_callback("TN", $tone) if ref($tone) eq "CODE";
	&validate($tone, INVALID_TONE, undef, TONES);

	$self->Do("TN", $tone);
}
sub ToneFreq { &TN(@_); }

##################
# DTMF Transmission Speed
#
# Syntax: 
# TSP [0|1]
# TSP [SLOW|FAST]
# Alias: DTMF_Speed
#
sub TSP {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("TSP", $setting) if ref($setting) eq "CODE";
	&validate($setting, "Invalid TSP setting, expected SLOW/FAST [0|1]",
		undef, SLOW, FAST);

	$self->Do("TSP", $setting);
}
sub DTMF_Speed { &TSP(@_); }

##################
# Transmit
# 
# Syntax: 
# TX [0|1]
# TX [A|B]
# Alias: Transmit
#
# WARNING: THIS WILL CAUSE THE D7 TO TRANSMIT UNTIL AN RX COMMAND IS RECEIVED
# UNLESS THE D7'S TX INHIBIT IS ENABLED.
#
sub TX {
	my $self = shift;
	my $band = shift;

	return $self->add_callback("TX", $band) if ref($band) eq "CODE";
	&validate($band, INVALID_BAND, undef, BAND_A, BAND_B);

	$self->Do("TX", $band);
}
sub Transmit { &TX(@_); }

##################
# DTMF Transmit Hold
#
# Syntax: 
# TXH [0|1] 
# TXH [OFF|ON]
# Alias: DTMF_TransmitHold
#
sub TXH {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("TXH", $setting) if ref($setting) eq "CODE";
	&validate($setting, INVALID_ONOFF, undef, ON, OFF);

	$self->Do("TXH", $setting);
}
sub DTMF_TransmitHold { &TXH(@_) }

##################
# APRS Transmit Interval
#
# Syntax: TXI [0..7] 
# Alias: APRS_TransmitInterval
#
sub TXI {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("TXI", $setting) if ref($setting) eq "CODE";
	&validate($setting, "Invalid interval, expected 0..7", undef, 0..7);

	$self->Do("TXI", $setting);
}
sub APRS_TransmitInterval { &TXI(@_); }

##################
# TX Inhibit
#
# Syntax: TXS [0|1]
# Alias: TransmitInhibit
#
sub TXS {
	&Simple_OnOff("TXS", @_);
}
sub TransmitInhibit { &TXS(@_); }

##################
# Measurement Units
#
# Syntax: 
# UNIT [0|1]
# UNIT [ENGLISH|METRIC]
# Alias: Unit
#
sub UNIT {
	my $self = shift;
	my $setting = shift;

	return $self->add_callback("UNIT", $setting) if ref($setting) eq "CODE";
	&validate($setting, "Invalid unit selection, expected ENGLISH/METRIC [0|1]",
		undef, METRIC, ENGLISH);

	$self->Do("UNIT", $setting);
}
sub Unit { &UNIT(@_); }

##################
# Adjust the Frequency
#
# Syntax: UP
# Alias: Up
#
sub UP {
	my $self = shift;
	my $blah = shift;

	return $self->add_callback("DW", $blah) if ref($blah) eq "CODE";
	&validate($blah, NOWRITE, undef);

	$self->Do("UP");
}
sub Up { &UP(@_); }

##################
# APRS Unprotocol String
#
# Syntax: UPR unprotocol string
# Alias: APRS_Unprotocol
#
sub UPR {
	&Simple_Text("UPR", @_);
}
sub APRS_Unprotocol { &UPR(@_); }

##################
# VCS Shutter
#
# Syntax: 
# VCS [0|1]
# VCS [OFF|ON]
# Alias: SSTV_Shutter
#
sub VCS {
	&Simple_OnOff("VCS", @_);
}
sub SSTV_Shutter { &VCS(@_); }

##################
# VMC Band Mode
#
# Syntax: 
# VMC [0|1],[0|2|3]
# VMC [A|B], [VFO|Memory|Call]
# Alias: Mode
#
sub VMC {
	my $self = shift;
	my $mode = shift;

	return $self->add_callback("VMC", $mode) if ref($mode) eq "CODE";
	&validate($mode, "Invalid mode, expected VFO/MEMORY/CALL (0|2|3)",
		undef, 0,2,3);

	$self->Do("VMC", $mode);
}
sub Mode { &VMC(@_); }

##################
# Read VFO Frequency
#
# Syntax: VR vfo 
# Alias: VFORead
#
# Reads the currently set frequency for VFO band vfo.
#
sub VR {
	my $self = shift;
	my $vfo = shift;

	return $self->add_callback("VR", $vfo) if ref($vfo) eq "CODE";
	&validate($vfo, "Invalid VFO, expected 1/2/3/6", 1,2,3,6);

	$self->Do("VR", $vfo);
}

##################
# Write VFO Frequency
#
# Syntax: VW vfo,freq_in_Hz,step,?,rev,tone,ctcss,?,tonefreq,?,ctcssfreq,ofs,mode
# Alias: VFOWrite
#
# Sets the VFO frequency for the specified VFO to the parameters specified.
#
sub VW {
	my $self = shift;
	my ($vfo, $freq, $step, $x1, $reverse, $tone, $ctcss, $x2,
		$tonefreq, $x3, $ctcssfreq, $offset, $mode) = @_;

	return $self->add_callback("VW", $vfo) if ref($vfo) eq "CODE";
	&validate($vfo, "Invalid VFO, expected 1/2/3/6", 1,2,3,6);
	croak("Invalid frequency, expected integer Hz") if $freq !~ /^\d+$/;
	&validate($step, "Invalid step range, expected 0..9", 0..9);
	&validate($reverse, INVALID_ONOFF, ON, OFF);
	&validate($tone, INVALID_ONOFF, ON, OFF);
	&validate($ctcss, INVALID_ONOFF, ON, OFF);
	&validate($tonefreq, "Invalid PL freq, expected 1,3..39 (use ToTone method?)",
     TONES);
	&validate($ctcssfreq, "Invalid CTCSS freq, expected 1,3..39 (use ToTone method?)",
     TONES);
	croak("Invalid repeater offset, expected integer Hz") if $offset !~ /^\d+$/;
	&validate($mode, INVALID_MODE, FM, AM);
	$self->Do("VW", $vfo, sprintf("%011d", $freq), $step, $x1 ? $x1 : 0,
		$reverse, $tone, $ctcss, $x2 ? $x2 : 0, $tonefreq, $x3 ? $x3 : 0,
		$ctcssfreq, sprintf("%011d", $offset), $mode);
}

# UNKNOWNS

sub CR { &Unknown("CR", @_); }
sub CW { &Unknown("CW", @_); }
sub GC { &Unknown("GC", @_); }
sub PC { &Unknown("PC", @_); }
sub SR { &Unknown("SR", @_); }
sub TH { &Unknown("TH", @_); }
sub TT { &Unknown("TT", @_); }
sub CIN { &Unknown("CIN", @_); }
sub CTD { &Unknown("CTD", @_); }
sub LAN { &Unknown("LAN", @_); }
sub MIN { &Unknown("MIN", @_); }
sub MNF { &Unknown("MNF", @_); }
sub MSH { &Unknown("MSH", @_); }
sub RBN { &Unknown("RBN", @_); }
sub STM { &Unknown("STM", @_); }
sub STR { &Unknown("STR", @_); }
sub STP { &Unknown("STP", @_); }
sub STT { &Unknown("STT", @_); }
sub TXN { &Unknown("TXN", @_); }
sub TYD { &Unknown("TYD", @_); }
sub ULC { &Unknown("ULC", @_); }

1;

__END__

=head1 NAME

THD7 - Perl module providing control to a Kenwood TH-D7 radio via serial port

=head1 SYNOPSIS

    use THD7 qw(:constants :functions);

    my $Radio = new THD7 ("/dev/ttyS0");
    $Radio->Band(BAND_A);
    $Radio->DataBand(BAND_A);
    $Radio->TNC(ON);
    $Radio->APRS_TransmitInterval(1);
    $Radio->APRS_Beacon(ON);


When running in the Windows environment, specify the path to the Win32
SerialPort configuration file, as such:

    my $configuration = "D:\\MyRadio\\COM6port.cfg";
    my $radio = new THD7 ($configuration);


=head1 ABSTRACT

This module allows you to perform real-time control over the Kenwood
TH-D7 radio via a serial port.

In its simplest usage, you can send commands to configure your D7 as
if you were entering them on the D7's keypad.  By using the more
advanced functions such as Polling, you can construct callback functions
that will be called whenever the D7 does something (like receive a
transmission or is reconfigured via the D7's keypad).

The current version of F<THD7.pm> should always be available via CPAN or:

    http://fastolfe.net/ham/THD7.pm

=head1 DESCRIPTION

Before interacting with the radio in any way, an object must be
created and tied to the serial port where the D7 is connected.  This
is done like this:

    use THD7 qw/:constants :functions/;
    my $Radio = new THD7 ("/dev/ttyS0");

The C<:constants> and C<:functions> tags import certain constants and
conversion functions described later on.  These will be useful and their
use is encouraged.

=head2 BASIC CONTROL

Now that you've got your THD7 object opened and connected to a
serial port, you can start sending commands to the D7 and querying
the D7 settings.  Nearly all of the commands listed here are readable
and writable.  If you call a method without specifying a setting, the
current setting will be returned.  Unless otherwise noted, the returned
values will exactly match the argument list.

Most methods have two names.  The short name matches the command string
sent to the D7 (ARL, BAL, BUF) while the long name is a more descriptive
version and should be used to maximize readability.

    $Radio->Band();		# Returns current band
    $Radio->Band(BAND_A);	# Sets the band to band A
    $Radio->Band();		# Returns 0 (BAND_A)

Here is a list of all control and query functions available:

=over 4

=item B<AI> [I<on_off>]

Turns on/off status and reporting notifications.  See the section
on Polling and callback functions for more information about this.
I<on_off> can be either B<ON> or B<OFF>.  Leave this off unless you're
going to be using B<Poll> to retrieve the information.  There are no
keystrokes available on the D7 to modify this value.

    $Radio->AI(ON);

=item B<VHFAIP> [I<on_off>]  (AIP)

Turns on/off the Advanced Intercept Point feature.  Equivalent to
pressing [MENU], [1], [5], [6].

=item B<APO> [I<setting>]

Turns on/off the Auto Power-Off feature.  I<Setting> can take one of
three constants: OFF, APO_30, APO_60 (0, 1 or 2).  NOTE: An additional
argument is returned from this function (or by polling).  When the
argument is set to ON, the D7 is about to power down because of the
APO setting.

    $Radio->APO(APO_30);	# Turn off after 30 minutes.

    # After 30 minutes, your callback function receives an APO
    # event with an additional argument, set to 1.  (See below for
    # information about Polling and callback functions):

    sub APO_callback {
        my ($name, $APO_setting, $about_to_shut_down) = @_;

        if ($about_to_shut_down) {
            print "WARNING! D7 about to shut down!\n";
        } else {
            print "APO setting now: $APO_setting\n";
        }
    }

Equivalent to pressing [MENU], [1], [2], [2].

=item B<APRS_Beacon> [I<on_off>]  (BCN)

Turns on/off the APRS beacon mode.  Equivalent to pressing [BCON].

=item B<APRS_Comment> [I<setting>]  (POSC)

Sets/retrieves the APRS positional comment.  The I<setting> is an
integer from 0 to 7:

    0   Off Duty
    1   Enroute
    2   In Service
    3   Returning
    4   Committed
    5   Special
    6   Priority
    7   Emergency

    $Radio->APRS_Comment(1);   # We're now enroute!

Note that setting this to 5 or greater will cause your call sign to appear
with red flashing lights and alarm klaxons with some APRS installations.

Equivalent to pressing [MENU], [2], [4].

=item B<APRS_Icon> [I<user_defined> I<icon>]  (ICO)

Sets/retrieves the current icon setting.  By default, the D7 has
16 built-in icons (numbered from 0 to E, hex).  You can either set
I<user_defined> to zero (0) and use this number to specify a built-in
icon, or you can set I<user_defined> to 1 and specify your own two-byte
APRS icon as your I<icon>.  Equivalent to pressing [MENU], [2], [5].

    $Radio->APRS_Icon(0, 8);   # A little car

=item B<APRS_MyCall> [I<call>]  (MYC)

Sets/retrieves the call sign for APRS packets.  Equivalent to pressing
[MENU], [2], [1].

=item B<APRS_Path> [I<path>]  (PP)

Sets/retrieves the current APRS path (e.g. "RELAY,WIDE").  Equivalent
to pressing [MENU], [2], [8].

=item B<APRS_PosLimit> [I<distance>]  (ARL)

Limit APRS notifications to I<distance> miles/kilometers.  This value
must be divisible by ten (10).  Equivalent to pressing [MENU], [2], [B].

    $Radio->APRS_PosLimit(500);    # 500 mi/km
    $Radio->APRS_PosLimit(499);    # Invalid
    $Radio->APRS_PosLimit(490);    # OK

=item B<APRS_Status> [I<text>]  (STAT)

Sets/retrieves the current APRS status text.  Equivalent to pressing
[MENU], [2], [6].

=item B<APRS_TransmitMode> [I<setting>]  (DTX)

Sets/retrieves the current APRS transmit mode.  I<Setting> can be any of
B<MANUAL>, B<PTT> or B<AUTO>.  Equivalent to pressing [MENU], [2], [9].

=item B<APRS_Unprotocol> [I<string>]  (UPR)

Sets/retrieves the current APRS Unprotocol string.  Equivalent to pressing
[MENU], [2], [A].

=item B<AutoOffset> [I<on_off>]  (ARO)

Turns on/off automatic repeater offsets.  Equivalent to pressing [MENU] +
[1], [5], [1].

=item B<Balance> [I<balance>]  (BAL)

Adjusts the speaker balance between the two bands.  Equivalent to pressing
[BAL].

    Value  BAND_A  BAND_B
    =====================
        0    100%      0%
        1     75      25
        2     50      50
        3     25      75
        4      0     100

=item B<Band> [I<band>]  (BC)

Switches the currently selected band.  I<band> can be either B<BAND_A> or
B<BAND_B>.  Equivalent to pressing [A/B].

=item B<BatterySave> [I<setting>]  (SV)

Sets/retrieves the current Battery Save setting.  I<Setting> is one of
the following:

    0   Off
    1   0.2s
    2   0.4
    3   0.6
    4   0.8
    5   1
    6   2
    7   3
    8   4
    9   5

Equivalent to pressing [MENU], [1], [2], [1].

=item B<Beep> [I<setting>]  (BEP)

Turns on/off the key/data notification beep.  I<Setting> can be B<OFF>,
B<KEY>, <KEY_DATA> or <ALL>.  Equivalent to pressing [MENU], [1] +
[5], [3].

=item B<Bell> I<band> [I<on_off>]

Turns on/off bell notification for the specified band.  I<Band> must be
either B<BAND_A> or B<BAND_B>.  Equivalent to pressing [F], [ENT].

=item B<Buffer> I<band> [I<frequency>, I<step>, I<x1>, I<reverse>, I<tone>, 
I<CTCSS>, I<x2>, I<tonefreq>, I<x3>, I<CTCSSfreq>, I<offset>, I<mode>]  (BUF)

This function sets or retrieves the current frequency information for
the specified band (B<BAND_A> or B<BAND_B>).  "B<Set>" is an alias for
this method.  The specified band must be in B<VFO> mode (via B<Mode)
for this call to succeed.  When making changes via this method, ALL
arguments are required:

I<frequency> Integer frequency value in Hz

I<step>      Integer step value; see 
          L<"HELPER FUNCTIONS"> later for 
          information on how to generate this 
          value

I<reverse>   Reverse repeater offset (B<ON> or B<OFF>)

I<tone>      PL tone enabled (B<ON> or B<OFF>)

I<CTCSS>     CTCSS tone enabled (B<ON> or B<OFF>)

I<tonefreq>  PL tone frequency; see 
          L<"HELPER FUNCTIONS"> later for 
          information on how to generate this 
          value

I<CTCSSfreq> ditto

I<offset>    Repeater offset in Hz

I<mode>      Modulation mode (B<FM> or B<AM>)

I<x1 x2 x3>  Unknown (set to 0?)

For an easier method to set/retrieve the current frequency without
all of that extra crap, see the B<Freq> method.

=item B<ChannelMode> [I<on_off>]  (CH)

Activates the channel display mode.  Effectively places the D7 in
a mode where the user may only navigate the channel list.  See the
D7 manual page 31 ("CHANNEL DISPLAY") for other restrictions.
Equivalent to pressing POWER OFF, [A/B]+ POWER ON.

=item B<Contrast> [I<setting>]  (CNT)

Adjust the contrast of the LCD display.  Valid settings are integers
from 1 to 16.  Equivalent to pressing [MENU], [1], [1], [2].

=item B<CTCSS> [I<on_off>]  (CT)

Enable/disable CTCSS.  Equivalent to pressing [F], [3].

=item B<CTCSSFreq> [I<tone>]  (CTN)

Set/retrieve the CTCSS tone frequency.  I<Tone> is an integer value
from 1 to 39.  See the B<ToTone> and B<FromTone> methods described in
L<"HELPER FUNCTIONS"> for information on how to generate
this value.  Equivalent to pressing [F], [4].

=item B<DataBand> [I<band>]  (DTB)

Sets/retrieves the current data band selection (B<BAND_A> or B<BAND_B>).
Equivalent to pressing [MENU], [1], [4], [1].

=item B<DCDSense> [I<setting>]  (DS)

Sets/retrieves the DCD sense setting.  Valid I<setting>s are B<DATA>
or B<BOTH>.

=item B<Down>  (DW)

Adjusts the frequency downward by the current step setting.  
See also: B<Up>

=item B<DTMF_Name> I<memory> [I<name>]  (DMN)

Sets/retrieves the DTMF memory name for location I<memory>.  Equivalent
to pressing [MENU], [1], [3], [1].

=item B<DTMF_Memory> I<memory> [I<number>]  (DM)

Sets/retrieves the DTMF string for location I<memory>.  Equivalent to
pressing [MENU], [1], [3], [1].

=item B<DTMF_Pause> [I<setting>]  (PT)

Sets/retrieves the current DTMF pause setting.  I<Setting> is an
integer representing one of these timings:

    0   100ms
    1   200
    2   500
    3   750
    4   1000
    5   1500
    6   2000

Equivalent to pressing [MENU], [1], [3], [4].

=item B<DTMF_Speed> [I<setting>]  (TSP)

Sets/retrieves the current DTMF speed setting.  Valid I<setting>s are
B<SLOW> or B<FAST>.  Equivalent to pressing [MENU], [1], [3], [2].

=item B<Dual> [I<on_off>]  (DL)

Activate/Deactivate the dual band feature of the HT.  Equivalent to
pressing [DUAL].

=item B<Duplex> [I<setting>]  (DUP)

Activates/deactivates full duplex mode.  I<Setting> can be either B<FULL>
(ON) or B<HALF> (OFF).  Equivalent to pressing [DUP].

=item B<Freq> [I<frequency> I<step>]  (FQ)

The easy way to set/retrieve the current frequency (as opposed to its
big brother, B<Buffer>).  I<Frequency> is in Hz and I<step> should be
set via B<ToStep> described under L<"HELPER FUNCTIONS">.

=item B<FreqList>  (FL) READ-ONLY

Returns four pairs of arguments, the first in the pair being the lower
extent for an available band, the second being the upper extent.  The
values are in MHz (e.g. "00118", though you can treat it numerically).

=item B<GPS> [I<on_off>]  (GU)

Turns on/off support for an attached NMEA-compatible GPS receiver.  At
the present time, this is a simple boolean B<ON>/B<OFF> setting, but if
Kenwood ever adds sport for additional receiver types, you can simply
use the appropriate integer offset in place of a constant.  B<NMEA> is
synonymous with B<ON>.  Equivalent to pressing [MENU], [2], [2].

=item B<ID>  (GU) READ-ONLY

Returns the ID string associated with the HT, e.g. "TH-D7".

=item B<Lock> [I<on_off>]  (LK)

Lock/unlock the radio keypad.  Equivalent to pressing [F] (1 s)

=item B<Lamp> [I<on_off>]  (LMP)

Set/check the status of the LCD display lamp.  Momentary lighting
of the lamp via the [LAMP] button doesn't count.  Equivalent to
pressing [F], [LAMP].

=item B<Memory> I<band> [I<channel>]  (MC)

Retrieve or set the current memory channel for the specified band.
I<Channel> is any valid channel number supported by that band.
Equivalent to selecting [MR] mode and entering a channel number.

The specified band must be in B<MEMORY> mode (via B<Mode>) for this
call to succeed.

Whenever this command is issued or received, it will be followed
by callbacks to B<Memory> (yes, again, if issued), B<MemoryLock>,
B<MemoryName> and B<Buffer> to describe the contents of the channel.
Be sure you're calling B<Poll> to catch these if B<AI> is enabled.

=item B<MemoryLock> I<band> [I<on_off>]  (MCL)

Turns on/off the "locked" attribute for the displayed memory channel
for the specified band.  The specified band must be in B<VFO> mode (via
B<Mode> for this call/query to succeed.  Equivalent to pressing [F], [0].

=item B<MemoryName> I<x1> I<channel> [I<name>]

Set/retrieve the 8-character text name associated with a memory
channel.  I<x1> is unknown and should probably be set to zero or something.

=item B<Message> [I<text>]  (MES)

Set/retrieve power-on message.  Equivalent to pressing [MENU], [1], [1],
[1].

=item B<Mode> I<band> [I<mode>]  (VMC)

Sets the specified band's mode.  Valid I<mode>s are B<VFO>, B<MEMORY>
and B<CALL>.

=item B<Modulation> [I<mod>]  (MD)

When in the 118MHz band, the D7 can operate in B<AM> or B<FM> mode.
Use this method to select.  Equivalent to pressing [F], [6].

=item B<MemoryRead> I<x1> I<x2> I<channel>

Returns the contents of memory location I<channel>.  The format of the
returned values are identical to the arguments to B<MemoryWrite> below,
except there's an additional argument at the beginning of the list
(I<x1>, whatever that is).  I don't know what I<x2> is either.

=item B<MemoryWrite> I<x1> [I<channel>, I<frequency>, I<step>, I<x2>,
I<reverse>, I<tone>, I<CTCSS>, I<x3>, I<tonefreq>, I<x4>, I<CTCSSfreq>,
I<offset>, I<mode>, I<x5>]  (BUF)

This function writes a frequency to memory channel I<channel>.
When making changes via this method, ALL arguments are required:

I<channel>   Memory channel

I<frequency> Integer frequency value in Hz

I<step>      Integer step value; see 
          L<"HELPER FUNCTIONS"> later for 
          information on how to generate this 
          value

I<reverse>   Reverse repeater offset (B<ON> or B<OFF>)

I<tone>      PL tone enabled (B<ON> or B<OFF>)

I<CTCSS>     CTCSS tone enabled (B<ON> or B<OFF>)

I<tonefreq>  PL tone frequency; see 
          L<"HELPER FUNCTIONS"> later for 
          information on how to generate this 
          value

I<CTCSSfreq> ditto

I<offset>    Repeater offset in Hz

I<mode>      Modulation mode (B<FM> or B<AM>)

I<x1 x2 x3 x4 x5>  Unknown (set to 0?)

=item B<Monitor> [I<on_off>]  (MON)

Behaves exactly like pressing the [MONI] button.  Similar in behavior
to B<Squelched>, but it uses the currently selected band.  When B<AI>
is on, this is immediately followed by a B<Squelched> (BY) callback.

=item B<Offset> I<offset>  (OS)

Sets/retrieves the current repeater offset.  I<Offset> is specified
in Hz.  Equivalent to pressing [F], [5].

    $Radio->Offset(600000);   # 600kHz offset

=item B<Packet> I<on_off>  (TS) WRITE-ONLY

Places the TNC in/out of packet mode.  This command is an odd one,
since you can't read the current setting from it, and internally, B<ON>
and B<OFF> are reversed (you don't have to worry about this though).
It's also the only "command" available while in packet mode.  Another
peculiarity about it is that the callback is actually sent with the
command "TS", but we compensate for that in the callback code and return
"TC".  This might change in the future.

See the section L<"PACKET USE"> below for information on using F<THD7.pm>
and the D7 with packet mode.

=item B<Position> [I<posit>]  (MP)

Set/receive current GPS position.  The I<posit> is a string of 17
numbers arranged like this:

    AABBBBBCDDDEEEEEF

    A   Latitude degrees
    B   Latitude minutes without decimal point (12.34 -> 1234)
    C   0=north, 1=south
    D   Longitude degrees
    E   Longitude minutes without decimal point
    F   0=east 1=west

You probably want to use the B<ToPosit> and B<FromPosit> methods
described under L<"HELPER FUNCTIONS"> to convert between this format
and a readable format automatically.  Equivalent to pressing [POS].

=item B<ProgrammableVFO> I<VFO> [I<low> I<high>]  (PV)

Sets/retrieves frequency ranges for the VFO's in the HT.  You can
set a programmable VFO via this method by specifying the low and
high frequencies in MHz.  Available VFO's are:

    1   Air
    2   VHF A
    3   VHF B
    6   UHF

Equivalent to pressing [F], [7].

=item B<Receive>  (RX)

Issuing this command causes the transceiver to stop transmitting.
The D7 returns this when switching out of Transmit/TX mode.  No
arguments are sent or returned.  See B<Transmit>.

=item B<Reverse> [I<on_off>]  (EV)

Sets reverse mode B<ON> or B<OFF>.  Equivalent to pressing [REV].

=item B<ScanResume> [I<setting>]  (SCR)

Sets/retrieves the current Scan Resume setting.  Possible I<setting>s
are B<TIME>, B<CARRIER> and B<SEEK>.  Equivalent to pressing [MENU],
[1], [5], [2].

=item B<Shift> [I<setting>]  (SFT)

Sets/adjusts the current repeater shift setting.  Valid I<setting>s are
B<OFF>, B<NEGATIVE> or B<POSITIVE>.  Equivalent to pressing [F], [MHz].

=item B<SignalMeter> I<band>  (SM)

Check/report the current signal meter on the specified I<band>.  The
returned arguments will be I<band> and the reported signal, which
ranges from 0 (no signal) to 5.

Whenever the squelch is opened or closed, the SignalMeter callback
function is called with the signal level of the received transmission.

=item B<Sky_CommanderCall> [I<call>]  (SCC)

Sets/retrieves the SkyCommand Commander Call.  Equivalent to [MENU],
[4], [1].

=item B<Sky_TransporterCall> [I<call>]  (SCT)

Sets/retrieves the SkyCommand Transporter Call.  Equivalent to [MENU],
[4], [2].

=item B<Sky_Tone> [I<tone>]  (SKTN)

Sets/retrieves the Sky Command Access Tone.  As with the B<Tone> and
B<CTCSS> methods, you probably want to make use of the B<ToTone> and
B<FromTone> methods below to get the correct arguments.

=item B<Squelch> I<band> [I<setting>]  (SQ)

Set the squelch for the specified band (B<BAND_A> or B<BAND_B>.  Valid
I<setting>s are integers from 0 to 5, with 0 being open.  Equivalent
to pressing [F], [MONI].

=item B<Squelched> I<band> [I<open_closed>]  (BY)

Open or close the squelch on the specified band (B<BAND_A> or B<BAND_B>).
You may use the constants B<OPEN> or B<CLOSED> to set this value.
Equivalent to pressing [MONI].  See also: B<Monitor>

=item B<SSTV_CallColor> [I<color>]  (MAC)

Sets/retrieves the current color of your call sign as it appears with
SSTV images.  The I<color> argument is an integer from 0 to 7, but
fortunately, we have the constants B<BLACK>, B<BLUE>, B<RED>, B<MAGENTA>,
B<GREEN>, B<CYAN>, B<YELLOW> and B<WHITE> defined.  Equivalent to
pressing [MENU], [3], [2].

=item B<SSTV_Message> [I<message>]  (SMSG)

Sets/retrieves the current SSTV message.  Equivalent to pressing
[MENU], [3], [3].

=item B<SSTV_MessageColor> [I<color>]  (SMC)

Sets/retrieves the current SSTV message color.  Uses the same color
constants listed under B<SSTV_CallColor>.  Equivalent to pressing
[MENU], [3], [4].

=item B<SSTV_MyCall> [I<call>]  (SMY)

Sets/retrieves the current SSTV call sign.  Equivalent to pressing
[MENU], [3], [1].

=item B<SSTV_RSVMessage> [I<message>]  (RSV)

Sets/retrieves the current SSTV RSV message.  Equivalent to pressing
[MENU], [3], [5].

=item B<SSTV_RSVColor> [I<color>]  (RSC)

Sets/retrieves the current SSTV RSV message color.  Uses the same
color constants listed under B<SSTV_CallColor>.  Equivalent to pressing
[MENU], [3], [6].

=item B<SSTV_Shutter> [I<on_off>]  (VCS)

Activates/deactivates the SSTV VC shutter.  Equivalent to pressing
[MENU], [3], [9].

=item B<SSTV_Superimpose> [I<call> I<x1>]  (STC)

Presumably, superimposes I<call> over the SSTV image.  I don't know
what I<x1> is.  Equivalent to pressing [MENU], [3], [7].

=item B<SSTV_Mode>  (STS)

Presumably queries the VC for the current SSTV transmit mode.  Returned
values are unknown.  Equivalent to pressing [MENU], [3], [8].

=item B<Step> [I<step>]  (ST)

Sets/retrieves the current frequency step.  I<Step> is an integer
representing the following values:

    0     5 kHz
    1     6.25
    2    10
    3    12.5
    4    15
    5    20
    6    25
    7    30
    8    50
    9   100

You may wish to use the B<ToStep> and B<FromStep> methods described
below under L<"HELPER FUNCTIONS"> to do the conversions automatically.

=item B<TNC> [I<on_off>]

Activate/deactivate the TNC (APRS mode only).  There is no way to activate
or deactivate TNC packet mode except by pressing the [TNC] button on the
D7 keypad.  B<APRS> is an alias for B<TNC>.  Equivalent to pressing [TNC].

=item B<Tone> [I<on_off>]

Enable/disable PL tone.  Equivalent to pressing [F], [1].

=item B<ToneFreq> [I<freq>]

Set/retrieve current PL tone frequency.  As with most all tone
values, you might want to make use of the B<ToTone> and B<FromTone>
methods described below to determine the correct argument.
Equivalent to pressing [F], [2].

=item B<Transmit> [I<band>]  (TX)

Begin transmitting on the specified band.  B<BAND_A> is assumed if
no band is specified.  The B<RX> command must be issued to cease
transmitting.  Equivalent to pressing [PTT].

=item B<TransmitInhibit> [I<on_off>]  (TXS)

Enables/disables the TX Inhibit function, preventing transmissions.
Equivalent to pressing [MENU], [1], [5], [5].

=item B<TuneEnable> [I<on_off>]  (ELK)

Activate/deactivate the Tune Enable feature.  Equivalent to pressing
[MENU], [1], [5], [4].

=item B<Unit> [I<setting>]  (UNIT)

Set/retrieve the current English/metric setting.  Valid I<setting>s are
B<ENGLISH> or B<METRIC>.  Equivalent to pressing [MENU], [2], [C].

=item B<Up>  (UP)

Adjusts the frequency up by the current step setting.  
See also: B<Down>

=item B<VFORead> I<vfo>  (VR)

Reads the currently set frequency for the VFO in question.  See the
B<ProgrammableVFO> method for a list of valid VFO's.  Second and
further arguments follow the argument list of B<Buffer> starting
with the frequency in Hz.

=item B<VFOWrite> I<vfo> ...  (VW)

See B<Buffer> for the full argument list (I<band> is replaced with I<vfo>.
I<Vfo> is the VFO you want to adjust.  See B<ProgrammableVFO> for a list
of valid VFO's.

=back

=head2 CONSTANTS

Quite a lot of constants have been defined to make your job a bit
easier.  These constants are only available if you use the
C<:constants> import argument:

    use THD7 qw/:constants/;

This is a complete list of constants.  Use them where 
appropriate (as defined in the method's documentation above).  See
the F<THD7.pm> source code for the definitions to these constants
if, for whatever reason, you can't use them.

    BAND_A BAND_B
    ON OFF 
    KEY KEY_DATA ALL
    TIME CARRIER SEEK 
    DATA BOTH 
    SLOW FAST 
    APO_30 APO_60
    ENGLISH METRIC 
    MANUAL PTT AUTO 
    NMEA
    BLACK BLUE RED MAGENTA GREEN CYAN YELLOW WHITE
    HIGH LOW EL 
    OPEN CLOSED 
    FULL HALF 
    AIR VHF_A VHF_B UHF

=head2 HELPER FUNCTIONS

Some methods like B<ToneFreq> and B<Step> take an indexed value from
0 to n to mean any of a range of discreet values.  To aid in one's
sanity, a few helper functions were written to make the process of
converting between known values to their appropriate integer offset.

These functions are made available to your namespace if you used the
C<:functions> import argument:

    use THD7 qw/:functions/;
    $tone = ToTone(88.5);

However, they're always available as methods or if you qualify them with
the package name:

    use THD7;
    ...
    $tone = $Radio->ToTone(88.5);
    $tone = &THD7::ToTone(88.5);

=over 4

=item B<ToTone> and B<FromTone>

These functions convert between PL/CTCSS tone frequencies and their
appropriate integer offsets for sending to the D7.  Example:

    $Radio->ToneFreq(ToTone(88.5));       # Set 88.5Hz tone
    return FromTone($Radio->ToneFreq);    # returns 88.5

=item B<ToStep> and B<FromStep>

These functions convert between the frequency steps and their
appropriate integer counterparts.  Example:

    $Radio->Step(ToStep(10));             # Set 10kHz steps
    return FromStep($Radio->Step);        # returns 10

=item B<ToPosit> and B<FromPosit>

These functions convert between "readable" GPS longitude/latitude
coordinates and the numeric string used to set/retrieve position
from the D7 (via B<Position> (MP)).  Example:

    # Set a position of 12'34.56"N 98'54.32"W (west = negative)
    $Radio->Position(ToPosit(12, 34.56, -98, 54.32));

    # Print our position in a readable fashion:
    printf("%d'%2.2f\" %d'%3.2f\"", FromPosit($Radio->Position));

=back

=head2 POLLING AND CALLBACK FUNCTIONS

The D7 is capable of sending messages whenever something changes, either
via the keypad or if some internal state changes (like when receiving a
transmission).  The B<AI> method enables such notifications.

In order to handle these messages, you need to set up a callback function
for every method you want to listen for.  Every control method described
above can alternatively accept a single argument, a code reference to
a callback function.  A special value, B<NOCALLBACK> is used to clear
the callback function for a method.  For example:

    sub BandSwitch {
       my ($self, $command, $argument) = @_;
       printf("The band was just switched to band %s!\n",
           $argument == BAND_A ? "A" : "B");
    }

    $Radio->Band(\&BandSwitch);

    # Do something, Poll perhaps (see below)
    $Radio->Poll;

    $Radio->Band(NOCALLBACK);   # Clear the callback function

The arguments sent to your callback function will consist of I<$self>,
a reference to the THD7 object in question, I<$command>, the actual
D7 command being reported and I<@args>, a list of arguments (if any)
being reported for that command.  Unless otherwise noted, the argument
list will exactly match the argument list of the method in question.
E.g., the first argument to the B<Band> method is I<band>, which is what
you'll see as the first (well, third) argument to your callback function.

Now you just know how to set and clear callback functions.  In order
for the script to actually wait for something to happen, you can call
the B<Poll> method to check for an incoming event.  The following
methods are used:

=over 4

=item B<Poll> [I<timeout>]

Checks for waiting events from the D7.  If I<timeout> is undefined, this
method will block indefinitely until something is heard from the D7.
Set it to 0 to ensure it returns immediately.

In a scalar context, it returns undef if there was a timeout, 0 if an
event was received but no callback function defined to handle it, or
1 if an event was received and handled.  In a list context, the method
also returns the command name and arguments returned by the HT.

This method automatically activates the B<AI> mode if it's not already
activated.


=item B<PollOnResult> [I<on_off>]

This is off by default, but if turned on, will cause ALL response messages
will be routed through the Polling mechanism, including return values
from other methods.  Adding to the Band example above:

    $Radio->Band(BAND_A);     # Doesn't activate BandSwitch
    $Radio->PollOnResult(ON);
    $Radio->Band(BAND_A);     # BandSwitch is called before return

=item B<Callback> [I<coderef>]

Establishes a "default" callback function.  If we can't find a specific
callback function for a particular event, we'll try this one instead.
If I<coderef> is undefined, B<NOCALLBACK> is assumed (which clears it).

=back

=head2 PACKET USE

By enabling packet mode via the B<Packet> method, you're free to
communicate with the TNC using your own functions.  There are no methods
here to do that for you.  See the Kenwood D7 manual for information on
the TNC commands.  Some methods of interest are:

=over 4

=item B<BinaryMode> [I<on_off>]

Places the F<THD7.pm> module in "binary" mode (B<ON>), meaning
reads/writes are done in a binary friendly way (via syswrite(), select()
and sysread()).  I don't really know if this makes much of a difference,
but in "text" mode (B<OFF>), normal Perl conventions are used to read
single lines from the TNC, which is probably perfectly adequate.  This is
off by default, because it's tons more efficient.  You probably want to
turn this off after you're done using it and want to return the D7 to
a normal command state.

=item B<RawReceive> [I<timeout>]

Reads a chunk (line in "text" mode) of data from the D7.  Returns the
data/line read.

When reading data from the TNC in "binary" mode, there will always be
a very slight delay, since B<RawReceive> uses the select() timeout to
determine when enough data's been read.  That I<timeout> is by default
0.3 seconds.  In "text" mode, the I<timeout> argument is ignored and
can be undefined.

=item B<RawSend> I<data>

Sends the I<data> to the TNC.  In "text" mode, this is done via
print().  In "binary" mode, it's done via syswrite().

=back

If you don't trust these methods, or desire much greater control over
the socket/filehandle used here, the B<GetSocket> method will return
the D7's Perl filehandle.

=head1 BUGS

=over 4

=item * Several fields in the B<BUF> and B<MW> argument lists are still unknown.

=item * The following commands are implemented, but their function
is unknown.  Please send any protocol additions, hints or help to
either of the addresses below.  B<CR> B<CW> B<GC> B<GM> B<PC> B<SR> B<TH>
B<TT> B<CIN> B<CTD> B<LAN> B<MIN> B<MNF> B<MSH> B<NSFT> B<RBN>
B<TXN> B<TYD> B<ULC>

=item * The following commands are implemented and APPEAR to have something
to do with SSTV via the Kenwood VC.  If someone has a VC and would care to
do a bit of research into these commands, it would be much appreciated:
B<STM> B<STR> B<STP> B<STS> B<STT> 

=item * The serial port code needs some work.  Occasionally it fails to
open the port properly if the serial port's been used for something else
recently.  Maybe I should make use of some IO modules.

=item * In the HTML version of this documentation, the text in this section
is bold.  I have no idea why.

=back

=head1 AUTHOR

F<THD7.pm> was written by David Nesting, WL7RO, E<lt>wl7ro@fastolfe.netE<gt>.
Please send any bug reports, patches and comments to that address.
http://fastolfe.net/

The D7 protocol was reverse engineered by Darryl Smith,
VK2TDS, E<lt>vk2tds@ozemail.com.auE<gt> and David Nesting, WL7RO,
E<lt>wl7ro@fastolfe.netE<gt>.  The latest version of the protocol should
be available from http://www.ozemail.com.au/~vk2tds/d7.htm .

The F<THD7.pm> home page is at http://fastolfe.net/ham/thd7.html .

=head1 COPYRIGHT

Copyright (C) 1999, David Nesting, WL7RO, E<lt>wl7ro@fastolfe.netE<gt>

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

