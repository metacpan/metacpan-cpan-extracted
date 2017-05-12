# $Id: $

package Test::Device::SerialPort;

use Carp;
use Data::Dumper;

BEGIN {
	if ($^O eq "MSWin32" || $^O eq "cygwin") {
		eval "use Win32";
		warn "Timing Tests unavailable: $@\n" if ($@);
	} else {
		eval "use POSIX";
	}
} # end BEGIN

use strict;
use warnings;

require Exporter;

our $VERSION = '0.05';
our @ISA = qw(Exporter);
our @EXPORT= qw();
our @EXPORT_OK= qw();
our %EXPORT_TAGS = (STAT => [qw( MS_CTS_ON	MS_DSR_ON
                                MS_RING_ON	MS_RLSD_ON
                                MS_DTR_ON   MS_RTS_ON
                                ST_BLOCK	ST_INPUT
                                ST_OUTPUT	ST_ERROR
                                TIOCM_CD TIOCM_RI
                                TIOCM_DSR TIOCM_DTR
                                TIOCM_CTS TIOCM_RTS
                                TIOCM_LE
                               )],

                PARAM	=> [qw( LONGsize	SHORTsize	OS_Error
                                nocarp		yes_true )]);

Exporter::export_ok_tags('STAT', 'PARAM');

$EXPORT_TAGS{ALL} = \@EXPORT_OK;

#### Package variable declarations ####

my $cfg_file_sig="Test::Device::SerialPort_Configuration_File -- DO NOT EDIT --\n";

my %Yes_resp = (
		"YES"	=> 1,
		"Y"	=> 1,
		"ON"	=> 1,
		"TRUE"	=> 1,
		"T"	=> 1,
		"1"	=> 1
	       );

# mostly for test suite
my %Bauds = (
		1200	=> 1,
		2400	=> 1,
		9600	=> 1,
		57600	=> 1,
		19200	=> 1,
		115200	=> 1
	       );

my %Handshakes = (
		"none"	=> 1,
		"rts"	=> 1,
		"xoff"	=> 1
	       );

my %Parities = (
		"none"	=> 1,
		"odd"	=> 1,
		"even"	=> 1
	       );

my %Databits = (
		5	=> 1,
		6	=> 1,
		7	=> 1,
		8	=> 1
	       );

my %Stopbits = (
		1	=> 1,
		2	=> 1
	       );

my @binary_opt = (0, 1);
my @byte_opt = (0, 255);

## undef forces computation on first usage
my $ms_per_tick=undef;

my $Babble = 0;
my $testactive = 0;	# test mode active

# parameters that must be included in a "save" and "checking subs"

my %validate =	(
		ALIAS		=> "alias",
		BAUD		=> "baudrate",
		BINARY		=> "binary",
		DATA		=> "databits",
		E_MSG		=> "error_msg",
		EOFCHAR		=> "eof_char",
		ERRCHAR		=> "error_char",
		EVTCHAR		=> "event_char",
		HSHAKE		=> "handshake",
		PARITY		=> "parity",
		PARITY_EN	=> "parity_enable",
		RCONST		=> "read_const_time",
		READBUF		=> "set_read_buf",
		RINT		=> "read_interval",
		RTOT		=> "read_char_time",
		STOP		=> "stopbits",
		U_MSG		=> "user_msg",
		WCONST		=> "write_const_time",
		WRITEBUF	=> "set_write_buf",
		WTOT		=> "write_char_time",
		XOFFCHAR	=> "xoff_char",
		XOFFLIM		=> "xoff_limit",
		XONCHAR		=> "xon_char",
		XONLIM		=> "xon_limit",
		);

## simplified from Device::SerialPort version since emulation can be imperfect
## and only the test suite really uses this function
sub init_ms_per_tick
{
	my $from_posix=undef;
	my $errors="";

	# To find the real "CLK_TCK" value, it is *best* to query sysconf
	# for it.  However, this requires access to _SC_CLK_TCK.  In
	# modern versions of Perl (and libc) these this is correctly found
	# in the POSIX module.  Device::SerialPort tries several alternates
	# but we won't.
	eval { $from_posix = POSIX::sysconf(&POSIX::_SC_CLK_TCK); };
	if ($@) {
		 warn "_SC_CLK_TCK not found during compilation: $@\n";
	}
	if ($from_posix) {
		$ms_per_tick = 1000.0 / $from_posix;
	}
	$ms_per_tick = 10; # a plausible default for emulation
}

sub get_tick_count {
    if ($^O eq "MSWin32") {
	return Win32::GetTickCount();
    } 
    # POSIX clone of Win32::GetTickCount

    unless (defined($ms_per_tick)) {
	init_ms_per_tick();
    }

    my ($real2, $user2, $system2, $cuser2, $csystem2) = POSIX::times();
    $real2 *= $ms_per_tick;
    ## printf "real2 = %8.0f\n", $real2;
    return int $real2;
}

use constant SHORTsize	=> 0xffff;	# mostly for AltPort test
use constant LONGsize	=> 0xffffffff;

sub nocarp { return $testactive }

sub yes_true {
    my $choice = uc shift;
    ## warn "WCB choice=$choice\n";
    return 1 if (exists $Yes_resp{$choice});
    return 0;
}

sub debug {
    ## warn Dumper \@_;
    my $self = shift || '';
    return @binary_opt if (wantarray);
    if (ref($self))  {
        if (@_) { $self->{"_debug"} = yes_true ( shift ); }
        else {
	    my $tmp = $self->{"_debug"};
	    ## warn "WCB-B, $tmp\n";
            nocarp || carp "Debug level: $self->{ALIAS} = $tmp";
            return $self->{"_debug"};
        }
    } else {
	## warn "WCB-C\n";
	if ($self =~ /Port/) {
		# in case someone uses the pseudo-hash calling style
		# obj->debug on an "unblessed" $obj (old test cases)
		$self = shift;
	}
        if ($self) { $Babble = yes_true ( $self ); }
        else {
            nocarp || carp "Debug Class = $Babble";
            return $Babble;
        }
    }
}


sub new
{
    my($ref, $port) = @_;
    my $class = ref($ref) || $ref;
    # real ports start with some values, these are just for init
    my $self = {
        _device => $port,
        _alias => $port,
        _are_match => [ "\n" ],		# as programmed
        _compiled_match => [ "\n" ],	# with -re compiled using qr//
	_baudrate => 9600,
	_parity => 'none',
	_handshake => 'none',
	_databits => 8,
	_stopbits => 1,
	_user_msg => 0,
	_error_msg => 0,
	_read_char_time => 0,
	_read_const_time => 0,
	_no_random_data => 0,		# for test suite only
	_debug => 0,			# for test suite only
	_fake_status => 0,		# for test suite only
	_fake_input => chr(0xa5),	# X10 CM11 wakeup
	_rx_bufsize => 4096,		# Win32 compatibility
	_tx_bufsize => 4096,
	_LOOK => "",			# for lookfor and streamline
	_LASTLOOK => "",
	_LMATCH => "",
	_LPATT => "",
	_LATCH => 0,			# for test suite only
	_BLOCK => 0			# for test suite only
    };
    if ($^O eq "MSWin32" && $self->{_device} =~ /^COM\d+$/io) {
	$self->{_device} = '\\\\.\\' . $self->{_device};
	# required for Win32 COM10++, done for all to support testing
    }
    return bless ($self, $class);
}

## emulate the methods called by CM17.pm

sub dtr_active {1}

sub rts_active {1}

sub pulse_break_on {
    my $self = shift;
    my $delay = shift || 1;     # length of pulse, default to minimum
    select (undef, undef, undef, $delay/500);
    return 1;
}

sub pulse_dtr_off {		# "1" bit
    my $self = shift;
    my $delay = shift || 1;     # length of pulse, default to minimum
    select (undef, undef, undef, $delay/500);
    return 1;
}

## the select() call sleeps for twice $delay/1000 seconds
## in Win32::SerialPort or Device::SerialPort, this method turns the
## DTR signal OFF, waits $delay, then turns DTR back ON and waits $delay.
## $delay is the desired duration of the pulse in milliseconds.
## $delay is also used as the "recovery time" after a pulse.
## DTR is a hardware signal wired to a pin on the serial port connector.

sub pulse_rts_off {		# "0" bit
    my $self = shift;
    my $delay = shift || 1;
    select (undef, undef, undef, $delay/500);
    return 1;
}

sub pulse_dtr_on {
    my $self = shift;
    my $delay = shift || 1;     # length of pulse, default to minimum
    select (undef, undef, undef, $delay/500);
    return 1;
}

sub pulse_rts_on {
    my $self = shift;
    my $delay = shift || 1;     # length of pulse, default to minimum
    select (undef, undef, undef, $delay/500);
    return 1;
}

## Win32 version which allows setting Blocking and Error bitmasks for test
## backwards compatiblity requires Errors be set first

sub is_status {
    my $self		= shift;

    if (@_ and $testactive) {
        $self->{"_LATCH"} |= shift;
        $self->{"_BLOCK"} = shift || 0;
    }

    my @stat = ($self->{"_BLOCK"}, 0, 0);
    $self->{"_BLOCK"} = 0;
    push @stat, $self->{"_LATCH"};
    return @stat;
}

sub reset_error {
    my $self = shift;
    my $was  = $self->{"_LATCH"};
    $self->{"_LATCH"} = 0;
    return $was;
}

sub status {
    my $self		= shift;
    my @stat = $self->is_status;
    return unless (scalar @stat);
    return @stat;
}

## The fakestatus method does the same for modemline bits

sub fakestatus {
    my $self = shift;
    return unless (@_);
    $self->{"_fake_status"} = shift;
}

## In the emulator, the input method returns a character string as if
## those characters had been read from the serial port. It returns
## all the characters at once and sets the input buffer to 'empty'

sub input {
    return undef unless (@_ == 1);
    my $self = shift;
    my $result = "";

    if ($self->{"_fake_input"}) {
	$result = $self->{"_fake_input"};
	$self->{"_fake_input"} = "";
    }
    return $result;
}

sub save {
    my $self = shift;
    return unless (@_);

    my $filename = shift;
    unless ( open CF, ">$filename" ) {
        #carp "can't open file: $filename"; 
        return undef;
    }
    print CF "$cfg_file_sig";
    print CF "$self->{_device}\n";
	# used to "reopen" so must be DEVICE
    close CF;
    1;
}

sub start {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return unless (@_);
    my $filename = shift;

    unless ( open CF, "<$filename" ) {
        carp "can't open file: $filename: $!"; 
        return;
    }
    my ($signature, $name) = <CF>;
    close CF;
    
    unless ( $cfg_file_sig eq $signature ) {
        carp "Invalid signature in $filename: $signature"; 
        return;
    }
    chomp $name;
    my $self  = new ($class, $name);
    return 0 unless ($self);
    return $self;
}


sub are_match {
    my $self = shift;
    my $pat;
    my $re_next = 0;
    if (@_) {
	@{ $self->{"_are_match"} } = @_;
	@{ $self->{"_compiled_match"} } = ();
	while ($pat = shift) {
	    if ($re_next) {
		$re_next = 0;
	        eval 'push (@{ $self->{"_compiled_match"} }, qr/$pat/)';
	   } else {
	        push (@{ $self->{"_compiled_match"} }, $pat);
	   }
	   if ($pat eq "-re") {
		$re_next++;
	    }
	}
    }
    return @{ $self->{"_are_match"} };
}


# Set the baudrate
sub baudrate
{
    my($self, $baud) = @_;
    if ($baud) {
	return unless (exists $Bauds{$baud});
	$self->{_baudrate} = $baud;
    }
    if (wantarray) {
	return (keys %Bauds);
    }
    return $self->{_baudrate};
}

# Device::SerialPort::buffers() is a fake for Windows compatibility
sub buffers
{
    my $self = shift;
    if (@_) {
	return unless (@_ == 2);
	$self->{_rx_bufsize} = shift;
	$self->{_tx_bufsize} = shift;
    }
    return wantarray ? ($self->{_rx_bufsize}, $self->{_tx_bufsize}) : 1;
}

# true/false capabilities (read only)
# currently just constants in the POSIX case

# If this class implements wait_modemlines()
sub can_wait_modemlines
{
    return(1);
}

sub can_modemlines
{
    return(0); # option on some unix
}

sub can_intr_count
{
    return(0); # option on some unix
}

sub can_status
{
    return(1);
}

sub can_baud
{
    return(1);
}

sub can_databits
{
    return(1);
}

sub can_stopbits
{
    return(1);
}

sub can_dtrdsr
{
    return(1);
}

sub can_handshake
{
    return(1);
}

sub can_parity_check
{
    return(1);
}

sub can_parity_config
{
    return(1);
}

sub can_parity_enable
{
    return(1);
}

sub can_rlsd
{
    return ($^O eq 'MSWin32') ? 1 : 0;
}

sub can_rlsd_config
{
    return(1);
}

sub can_16bitmode
{
    return(0); # Win32 specific default off
}

sub can_ioctl
{
    return ($^O eq 'MSWin32') ? 0 : 1; # unix specific
}

sub is_rs232
{
    return(1);
}

sub can_arbitrary_baud
{
    return(0); # unix specific default off
}

sub is_modem
{
    return(0); # Win32 specific default off
}

sub can_rts
{
    return(1);
}

sub can_rtscts
{
    return(1);
}

sub can_xonxoff
{
    return(1);
}

sub can_xon_char
{
    return(1);
}

sub can_spec_char
{
    return(0);
}

sub binary
{
    return(1);
}

sub can_write_done
{
    return(0); # so test does not try to time
}

sub write_done
{
    return(0); #invalid with Solaris, VM and USB ports 
}

sub can_interval_timeout
{
    return ($^O eq 'MSWin32') ? 1 : 0;
}

sub can_total_timeout
{
    return(1);
}

## for test suite only
sub set_no_random_data {
    my $self = shift;
    if (@_) { $self->{_no_random_data} = yes_true ( shift ) }
    return $self->{_no_random_data};
}

sub user_msg {
    my $self = shift;
    if (@_) { $self->{_user_msg} = yes_true ( shift ) }
    return wantarray ? @binary_opt : $self->{_user_msg};
}

sub error_msg {
    my $self = shift;
    if (@_) { $self->{_error_msg} = yes_true ( shift ) }
    return wantarray ? @binary_opt : $self->{_error_msg};
}


sub close
{
    # noop
    return(1);
}

# Set databits
sub databits
{
    my($self, $databits) = @_;
    if ($databits) {
	return unless (exists $Databits{$databits});
	$self->{_databits} = $databits;
    }
    if (wantarray) {
	return (keys %Databits);
    }
    return $self->{_databits};
}

# Set handshake type property
sub handshake
{
    my($self, $handshake) = @_;
    if ($handshake) {
	return unless (exists $Handshakes{$handshake});
	$self->{_handshake} = $handshake;
    }
    if (wantarray) {
	return (keys %Handshakes);
    }
    return $self->{_handshake};
}

sub lookfor
{
    my $self = shift;
    if ($self->{_no_random_data}) {
	## redirect to faster version without stty emulation
	return $self->streamline(@_);
    }
    my $count = undef;
    if( @_ )
    {
        $count = $_[0];
    }

    # When count is defined, behave like read()
    if( $count > 0 )
    {
        return $self->read($count);
    }

    # Lookfor specific behaviour
    my $look = 0;
    my @patt = $self->are_match();

    # XXX What we do here?
    if( ! @patt )
    {
        @patt = ("\n");
    }

    if( rand(1) < 0.3 )
    {
        $look = 1;
    }

    return '' unless $look;

    # Return random data with appended one of the user-defined patterns

    my $data = $self->_produce_data(10);
    $data .= $patt[ rand(@patt) ];

    return($data);
}

## routines copied from Win32::SerialPort
sub lookclear {
    my $self = shift;
    if (nocarp && (@_ == 1)) {
        $self->{"_fake_input"} = shift;
    }
    $self->{"_LOOK"}	 = "";
    $self->{"_LASTLOOK"} = "";
    $self->{"_LMATCH"}	 = "";
    $self->{"_LPATT"}	 = "";
    return if (@_);
    1;
}

sub matchclear {
    my $self = shift;
    my $found = $self->{"_LMATCH"};
    $self->{"_LMATCH"}	 = "";
    return if (@_);
    return $found;
}

sub lastlook {
    my $self = shift;
    return if (@_);
    return ( $self->{"_LMATCH"}, $self->{"_LASTLOOK"},
	     $self->{"_LPATT"}, $self->{"_LOOK"} );
}

sub streamline {
    my $self = shift;
    my $size = 0;
    if (@_) { $size = shift; }
    my $loc = "";
    my $mpos;
    my $count_in = 0;
    my $string_in = "";
    my $re_next = 0;
    my $got_match = 0;
    my $best_pos = 0;
    my $pat;
    my $match = "";
    my $before = "";
    my $after = "";
    my $best_match = "";
    my $best_before = "";
    my $best_after = "";
    my $best_pat = "";
    $self->{"_LMATCH"}	 = "";
    $self->{"_LPATT"}	 = "";

    if ( ! $self->{"_LOOK"} ) {
        $loc = $self->{"_LASTLOOK"};
    }

    $loc .= $self->input;
    my $lenloc = length($loc);
    if ($size && ($lenloc < $size)) {
	    warn "Test Suite streamline length mismatch: requested: $size\n\tgot: $lenloc, data: $loc\n";
    }

    if ($loc ne "") {
        $self->{"_LOOK"} .= $loc;
	$count_in = 0;
	foreach $pat ( @{ $self->{"_compiled_match"} } ) {
	    if ($pat eq "-re") {
		$re_next++;
		$count_in++;
		next;
	    }
	    if ($re_next) {
		$re_next = 0;
	        if ( $self->{"_LOOK"} =~ /$pat/s ) {
		    ( $match, $before, $after ) = ( $&, $`, $' );
		    $got_match++;
        	    $mpos = length($before);
        	    if ($mpos) {
        	        next if ($best_pos && ($mpos > $best_pos));
			$best_pos = $mpos;
			$best_pat = $self->{"_are_match"}[$count_in];
			$best_match = $match;
			$best_before = $before;
			$best_after = $after;
	    	    } else {
		        $self->{"_LPATT"} = $self->{"_are_match"}[$count_in];
		        $self->{"_LMATCH"} = $match;
	                $self->{"_LASTLOOK"} = $after;
		        $self->{"_LOOK"}     = "";
		        return $before;
		        # pattern at start will be best
		    }
		}
	    }
	    elsif (($mpos = index($self->{"_LOOK"}, $pat)) > -1) {
		$got_match++;
		$before = substr ($self->{"_LOOK"}, 0, $mpos);
        	if ($mpos) {
        	    next if ($best_pos && ($mpos > $best_pos));
		    $best_pos = $mpos;
		    $best_pat = $pat;
		    $best_match = $pat;
		    $best_before = $before;
		    $mpos += length($pat);
		    $best_after = substr ($self->{"_LOOK"}, $mpos);
	    	} else {
	            $self->{"_LPATT"} = $pat;
		    $self->{"_LMATCH"} = $pat;
		    $before = substr ($self->{"_LOOK"}, 0, $mpos);
		    $mpos += length($pat);
	            $self->{"_LASTLOOK"} = substr ($self->{"_LOOK"}, $mpos);
		    $self->{"_LOOK"}     = "";
		    return $before;
		    # match at start will be best
		}
	    }
	    $count_in++;
	}
	if ($got_match) {
	    $self->{"_LPATT"} = $best_pat;
	    $self->{"_LMATCH"} = $best_match;
            $self->{"_LASTLOOK"} = $best_after;
	    $self->{"_LOOK"}     = "";
	    return $best_before;
        }
    }
    return "";
}

# non-POSIX constants commonly defined in termios.ph
use constant CRTSCTS	=> 0;
use constant OCRNL	=> 0;
use constant ONLCR	=> 0;
use constant ECHOKE	=> 0;
use constant ECHOCTL	=> 0;
use constant TIOCM_LE	=> 0x001;
use constant TIOCM_CD 	=> 0x040;
use constant TIOCM_RI 	=> 0x080;
use constant TIOCM_CTS 	=> 0x020;
use constant TIOCM_DSR 	=> 0x100;
#
## Next 4 use Win32 names for compatibility
sub MS_RLSD_ON { return ($^O eq 'MSWin32') ? 0x80 : TIOCM_CD; }
sub MS_RING_ON { return ($^O eq 'MSWin32') ? 0x40 : TIOCM_RI; }
sub MS_CTS_ON { return ($^O eq 'MSWin32') ? 0x10 : TIOCM_CTS; }
sub MS_DSR_ON { return ($^O eq 'MSWin32') ? 0x20 : TIOCM_DSR; }
#
# For POSIX completeness, but not on Win32
use constant TIOCM_RTS => 0x004;
use constant TIOCM_DTR => 0x002;
sub MS_RTS_ON { TIOCM_RTS; }
sub MS_DTR_ON { TIOCM_DTR; }
#
# "status"
use constant ST_BLOCK	=> 0;	# status offsets for caller
use constant ST_INPUT	=> 1;
use constant ST_OUTPUT	=> 2;
use constant ST_ERROR	=> 3;	# latched
#
# Return the status of the serial line signals
# Randomly activate signals...
sub modemlines
{
    my $self = shift;
    return $self->{_fake_status} if ($self->{_no_random_data}); # Test Suite
    my $status = 0;
    $status |= MS_CTS_ON  if rand(1) > 0.3;
    $status |= MS_DSR_ON  if rand(1) > 0.3;
    $status |= MS_RING_ON if rand(1) > 0.95;
    $status |= MS_RLSD_ON if rand(1) > 0.5;
    return $status;
}

# Set parity
sub parity
{
    my($self, $parity) = @_;
    if ($parity) {
	return unless (exists $Parities{$parity});
	$self->{_parity} = $parity;
    }
    if (wantarray) {
	return (keys %Parities);
    }
    return $self->{_parity};
}


sub parity_enable {
    my $self = shift;
    if (@_) {
        $self->{_parity_enable} = yes_true( shift );
    }
    return wantarray ? @binary_opt : $self->{_parity_enable};
}



# Produce random data
sub _produce_data
{
    my($self, $bytes) = @_;
    my @chars = ('A' .. 'Z', 0 .. 9, 'a' .. 'z' );
    my $data  = '';
    my $len   = int rand($bytes);

    for( 1 .. $len )
    {
        $data .= $chars[rand(@chars)];
    }
    return($data);
}

# Empty transmit and receive buffers
sub purge_rx {
    my $self = shift;
    $self->{_rx_buf} = '';
    return if (@_);
    return 1;
}

sub purge_tx {
    my $self = shift;
    $self->{_tx_buf} = '';
    return if (@_);
    return 1;
}

sub purge_all
{
    my $self = shift;
    $self->{_tx_buf} = '';
    $self->{_rx_buf} = '';
    return if (@_);
    return 1;
}

# Wait some time between a min and a max (seconds)
sub _random_wait
{
    my($self, $min, $max) = @_;
    my $time = $min + rand($max - $min);
    select(undef, undef, undef, $time);
    return();
}

# Read data from line. For us is "generate" some random
# data as it came from the serial line.
sub read
{
    my($self, $bytes) = @_;
    my $new_input = '';
    my $buf;

    # for test suite only
    if ($self->{_no_random_data}) {
	$buf = $self->input();
	$self->{_rx_buf} = '';
	my $size = length($buf);
	unless ($size == $bytes) {
	    warn "Test Suite input length mismatch: requested: $bytes\n\tgot: $size, data: $self->{_fake_input}\n";
	}
	return($size, $buf);
    }

    # Wait some random time
    $self->_random_wait(0, 0.5);

    # We can have or not input
    my $have_input = rand(1);

    if( $have_input > 0.7 )
    {
        $new_input = $self->_produce_data($bytes);
        $self->{_rx_buf} .= $new_input;
    }

    # Empty read buffer
    $buf = $self->{_rx_buf};
    $self->{_rx_buf} = '';

    return(length($buf), $buf);
}

sub read_char_time
{
    my $self = shift;
    if( @_ )
    {
        $self->{_read_char_time} = shift() / 1000;
    }
    return($self->{_read_char_time} * 1000);
}

sub read_const_time
{
    my $self = shift;
    if( @_ )
    {
        $self->{_read_const_time} = shift() / 1000;
    }
    return($self->{_read_const_time} * 1000);
}

sub read_interval
{
    die qq(Can't locate object method "read_interval" via package "Device::SerialPort");
}

# Set stopbits
sub stopbits
{
    my($self, $stopbits) = @_;
    if ($stopbits) {
	return unless (exists $Stopbits{$stopbits});
	$self->{_stopbits} = $stopbits;
    }
    if (wantarray) {
	return (keys %Stopbits);
    }
    return $self->{_stopbits};
}

# Randomly wait some time, and then return with status 1
sub wait_modemlines
{
    my $self = shift;
    $self->_random_wait(10, 60);
    return(1);
}

# Write data down the line
sub write
{
    my($self, $str) = @_;
    $self->_random_wait(0, 0.5);
    $self->{_tx_buf} .= $str;
    return(length($str));
}

## this alternate  write method decodes the commands sent to the CM11 and
## preloads the expected response via 'fakeinput'. Hence, it
## looks like a two-way conversation is occurring.

sub cm11_write {
    return unless (@_ == 2);
    my $self = shift;
    my $wbuf = shift;
    my $response = "";
    return unless ($wbuf);
    my @loc_char = split (//, $wbuf);
    my $f_char = ord (shift @loc_char);

    if ($f_char == 0x00) {
	    # start operation (sent after checksum is verified)
	$response = chr(0x55);	# emulator will respond with 'done'
	$self->fakeinput($response);
	return 1;
    }
    elsif ($f_char == 0xc3) {
	    # tell CM11 to send data waiting in the buffer
	    # issued after CM11 sends "data available" message (0x5a)
	$response = chr(0x03).chr(0x02).chr(0x6e).chr(0x62);
	     # Buffer contents which translate to 'A2AJ'
	$self->fakeinput($response);
	return 1;
    }
    else {
	    # else just compute the checksum and pass the command on
	    # for any other command written.
	my $ccount = 1;
	my $n_char = "";
	foreach $n_char (@loc_char) {
	    $f_char += ord($n_char);
	    $ccount++;
	}
	$response = chr($f_char & 0xff);
	$self->fakeinput($response);
	return $ccount;
    }
}

# Empty the write buffer
sub write_drain
{
    my($self) = @_;
    $self->{_tx_buf} = '';
    return(1);
}

sub buffer_max {
    my $self = shift;
    if (@_) {return undef; }
    return (4096, 4096);
}

sub device {
    my $self = shift;
    if (@_) { $self->{_device} = shift; }
    # should return true for legal names
    return $self->{_device};
}

sub alias {
    my $self = shift;
    if (@_) { $self->{_alias} = shift; }
    # should return true for legal names
    return $self->{_alias};
}



# Write serial port settings into external files
sub write_settings
{
    # noop
    return(1);
}


sub OS_Error { print "Test::Device::SerialPort OS_Error\n"; }

# test*.pl only - suppresses default messages
sub set_test_mode_active {
    return unless (@_ == 2);
    $testactive = $_[1];     # allow "off"
    my @fields = ();
    foreach my $item (keys %validate) {
         push @fields, "$item";
    }
    return @fields;
}

;

__END__

=head1 NAME

Test::Device::SerialPort - Serial port mock object to be used for testing

=head1 SYNOPSIS

    use Test::Device::SerialPort;
    my $PortObj = Test::Device::SerialPort->new('/dev/ttyS0');

    $PortObj->baudrate(19200);
    $PortObj->parity('none');
    $PortObj->databits(8);
    $PortObj->stopbits(1);

    # Simulate read from port (can also read nothing)
    my($count, $data) = $PortObj->read(100);

    print "Read random data from serial [$data]\n";

    # Simulate write to serial port
    $count = $PortObj->write("MY_MESSAGE\r");

    print "Written $count chars to test port\n";

    # ...

=head1 DESCRIPTION

Nothing more.
It's a test object that mimics the real Device::SerialPort thing.
Used mainly for testing when I don't have an actual device to test.

=head1 STATUS

Started as a really sketchy and cheap way to mock serial port
objects in unit tests.

Thanks to the work Bill Birthisel has put into this distribution,
C<Test::Device::SerialPort> should now mimick a serial port fairly
accurately.

=head1 SEE ALSO

=over

=item L<Device::SerialPort>

=item L<Win32::SerialPort>

=back

=head1 KNOWN LIMITATIONS

The configuration file methods B<save and start> have minimal support.
Settings are not saved or restored although a two_line config file is created.
B<restart> is not supported yet. Nor are lockfiles nor "quiet mode".
Tied filehandle methods are not supported yet either.

=head1 AUTHORS

Cosimo Streppone, <cosimo@cpan.org>

Additional support added by Bill Birthisel <wcbirthisel@alum.mit.edu>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, 2010 by Cosimo Streppone

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

