package Modbus::Client;

=head1 DESCRIPTION

This module provides a basic Modbus client for reading from and writing to
various ModBus serial slaves using RTU or ASCII modes.

=cut

use strict;
use 5.004;
use Exporter;
use POSIX ':termios_h';
use FileHandle;

use vars qw($VERSION @ISA @EXPORT);

$VERSION = '1.03';
@ISA = qw(Exporter);
@EXPORT = qw(M_RTU M_ASCII);
my ($RCSVERSION) = '$Revision: 1.3 $ ' =~ /\$Revision:\s+([^\s]+)/;

# There is magic in the values chosen for these constants, specifically in how
# many bytes are read from the device.
use constant M_RTU   => 1;
use constant M_ASCII => 2;

=head1 METHODS

The Modbus::Client module defines the following methods:

=over 4

=item Modbus::Client->new()

Create a new serial client to talk to a ModBus.  Accepts two kinds of
parameters - the first kind is the serial device the modbus is connected to.
If this type of parameter is specified, Modbus::Client optionally accept a
second paramater to define the baud rate.  By default, Modbus::Client will
initiate communications at 9600 baud, no parity.

    $bus = new Modbus::Client "/dev/cua00", POSIX::B19200;

The second type of parameter is a file handle.  If this parameter is passed,
it is assumed that you have initiated the connection, and Modbus::Client will
simply use the connection you have already established.  This allows you to
easily use different baud rates or to connect to a TCP port associated with a
serial-to-ether adapter, such as the Digi One SP.  For devices like this,
make sure you DISABLE software flow control!

    use FileHandle;
    use Socket;
    $fd = new FileHandle;
    $host = "something.yournet.com";
    $port = 2101;
    $remote = inet_aton($host)	|| die "No such host $host";
    socket($fd, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
				|| die "Can't create socket - $!";
    $paddr = sockaddr_in($port, $remote);
    connect($fd, $paddr)	|| die "Can't connect to $host:$port - $!";
    $fd->autoflush(1);
    $bus = Modbus::Client->new($fd);

NOTE FOR WINDOWS USERS: For finer control of the serial connection, it is
I<possibly> better if you open the connection and pass the FileHandle to the
I<new> method.  This is because Windows does not implement POSIX::Termios.

=cut

sub new {
    my ($class, $device, $speed, $addr) = @_;
    die "Missing device or filehandle in call to $class->new\n"	unless $device;
    my ($serial, $self);
    if (ref $device eq "FileHandle" || ref $device eq "GLOB") {
	$serial = $device;
	}
    else {
	if ($^O ne "MSWin32") {
	    $serial = new FileHandle($device, O_RDWR | O_NDELAY | O_NOCTTY) 
		or die "Can't open $device $!\n";

	    #
	    # System dependent?
	    # 1) Open enersure non-blocking, but then reset that flag (has to do
	    # 	with DTR not being asserted)
	    # 2) Set baud rate
	    # 3) Enable reader, don't monitor DTR, etc, 8 bits, 2 stop bits
	    #
	    my $cflag = CS8 | HUPCL | CREAD | CLOCAL;
	    my $lflag = 0;	# No local processing (raw mode)
	    my $iflag = IGNBRK | IGNPAR;
	    my $oflag = 0;	# No output post-processing
	    my $termios = POSIX::Termios->new();

	    $termios->getattr($serial->fileno())
		or die "getattr failed: $!\n";

	    $termios->setcflag($cflag);
	    $termios->setlflag($lflag);
	    $termios->setiflag($iflag);
	    $termios->setoflag($oflag);
	    $termios->setcc(VTIME, 10);	# 10 * .1 == 1 sec timeout on read
	    $termios->setcc(VMIN, 0);	# Purely time-based timeouts

	    $termios->setattr($serial->fileno(),TCSANOW)
		or die "setattr failed 1: $!\n";
	    $termios->setospeed($speed || POSIX::B9600)
		or die "setospeed failed: \$!\n";
	    $termios->setispeed($speed || POSIX::B9600)
		or die "setispeed failed: \$!\n";
	    $termios->setattr($serial->fileno(),TCSANOW)
		or die "setattr 2 failed: $!\n";

	    # This gets rid of all the special characters..
	    $termios->getattr($serial->fileno())
		or die "getattr failed: $!\n";
	    }

	$serial = new FileHandle($device, O_RDWR | O_NOCTTY)
	    or die "Can't open $device $!\n";
	}
    $serial->autoflush(0);

    $self = bless {
	fh    => $serial,
	clump => 125,
	mode  => M_RTU,
	debug => 0,
	}, $class;
    $self->{bus} = $self;	# Makes {mode} coding easier to self-reference

    return $self;
}

=item $bus->device()

Create a new device on a Modbus.  The single parameter is the device number.
Note that according to the Modbus spec, a device number of 0 is the broadcast
address.

    $unit = $bus->device(1);

=cut

sub device {
    my ($self, $addr) = @_;
    die "$self does not look like a Modbus conection\n"	unless ref $self;
    die "Missing device address in device()\n"	unless defined $addr;

    return bless {
	addr => $addr,
	bus  => $self,
	%{ $self }
	}, ref $self;
}

sub _my_read {
    my ($self, undef, $cnt) = @_;
    my ($buf, $chr, $rin, $rout);
    my $total = 0;

    vec($rin, $self->{fh}->fileno, 1) = 1;
    while ($cnt--) {
	last unless select($rout=$rin, undef, undef, 1);
	last unless sysread($self->{fh}, $chr, 1);
	$buf .= $chr;
	$total++;
	}
    if ($self->{bus}->{debug}) {
	print STDERR "Modbus::Client Reading $total chars: ";
	if ($self->{bus}->{mode} == M_RTU) {
	    for (0..length($buf)-1) {
		printf STDERR "%02x", ord(substr($buf,$_,1));
		}
	    print STDERR "\n";
	    }
	else {
	    print STDERR "'$buf'\n";
	    }
	}
    $_[1] = $buf;
    return $total;
    }

=item $unit->read_one()

The I<read_one> method is a convenience routine that is called with a single
modbus address to read, and it returns a single scalar value from that
register.  The I<read> method is more powerful, but also more complicated.

The API for the I<read_one> method does not distinguish between ModBus Coils,
Status Registers, Holding Registers, or Input Registers.  It makes the
necessary ModBus calls to get all of them to work.

=cut

sub read_one {
    my $self = shift;
    my $reg = shift;

    die "You must read_one from a specific device, not a modbus\n"
	unless $self->{addr};

    return ($self->read($reg))[0];
    }

=item $unit->read()

The I<read> method may be called with two kinds of parameters: a list of
addresses to read, or a reference to hash table (where the keys are the
addresses to read, and the values will be filled in by the method).

It may also be called in an array context (in which case it returns the
values of the registers that were read.  The order in which they are returned
is equal to the order specified (when called with an array of values) or in
sorted key order (when called with a reference to a hash table).

    @array = $unit->read(30001..30010);
    $hash  = $unit->read(10001..10037);

    %hash = map {$_, 1} (20007, 20012..20015, 30029, 40006)
    @array = $unit->read(\%hash);
    $hash  = $unit->read(\%hash);

If the method is called in a scalar context, then a reference to a hash table
is returned (where the keys are the register addresses and the values are the
values read).  The referenced hash will be the same as the input hash, or if
an array of addresses is passed as a parameter, the referenced hash will be
an anonymous one.

The API for the I<read> method does not distinguish between ModBus Coils,
Status Registers, Holding Registers, or Input Registers.  It makes the
necessary ModBus calls to get all of them to work, even if they are mixed in a
single invocation of the I<read> method.

General Reference registers are not presently supported, neither are FIFO
queues - ask and ye shall receive, though...

=cut

my @exception = ("",	# 0 == no exception
		 "ILLEGAL FUNCTION",
		 "ILLEGAL DATA ADRESS",
		 "ILLEGAL DATA VALUE".
		 "SLAVE DEVICE FAILURE",
		 "ACKNOWLEDGE",
		 "SLAVE DEVICE BUSY",
		 "NEGATIVE ACKNOWLEDGE",
		 "MEMORY PARITY ERROR",
		);

sub read {
    my $self = shift;
    my @regs = @_;
    my (@this_set, @retval, $regs, $base, $fn, $start, $cmd,
	$icnt, $ocnt, $tally);

    die "You must read from a specific device, not a modbus\n"
	unless $self->{addr};

    if (@regs == 1 && ref $regs[0] eq "HASH") {
	$regs = $regs[0];
	@regs = sort { $a <=> $b } keys %$regs;
	}
    else {
	$regs = { };
	}
    while (@regs) {
	# Collect adjacent registers into a set to read...
	@this_set = ();
	push @this_set, shift @regs;
	$tally = 1;
	CLUMP: while (@regs) {
	    last CLUMP if $regs[0] != $this_set[-1] + 1;  # Must be adjacent
	    last CLUMP if ++$tally > $self->{clump};	  # Limit clump size
	    push @this_set, shift @regs;
	    }
	if ($this_set[0]  > 0 && $this_set[0] < 10000) {
	    $base = 00001;
	    $fn = 0x01;
	    }
	elsif ($this_set[0] > 10000 && $this_set[0] < 20000) {
	    $base = 10001;
	    $fn = 0x02;
	    }
	elsif ($this_set[0] > 30000 && $this_set[0] < 40000) {
	    $base = 30001;
	    $fn = 0x04;
	    }
	elsif ($this_set[0] > 40000 && $this_set[0] < 50000) {
	    $base = 40001;
	    $fn = 0x03;
	    }
	else {
	    die "I don't know how to read registers like $this_set[0]\n";
	    }
	$start = $this_set[0] - $base;
	$cmd = pack('ccnn', $self->{addr}, $fn, $start, scalar(@this_set));
	if ($self->{bus}->{mode} == M_ASCII) {
	    $cmd =~ s/(.)/sprintf "%02x", ord($1)/ges;
	    _append_lrc($cmd);
	    $cmd = ":$cmd\r\n";
	    if ($self->{bus}->{debug}) {
		print STDERR "Modbus::Client Writing: $cmd";
		}
	    }
	else {
	    _append_crc($cmd);
	    if ($self->{bus}->{debug}) {
		print STDERR "Modbus::Client Writing: ";
		for (0..length($cmd)-1) {
		    printf STDERR "%02x", ord(substr($cmd,$_,1));
		    }
		print STDERR "\n";
		}
	    }
	syswrite($self->{fh}, $cmd);
	my ($buf, $tmp, $nbytes, $want, $got);
	# Read the echoed address
	$ocnt = $self->_my_read($tmp, $icnt = 1 * $self->{bus}->{mode});
	die "Unexpected return from Modbus device (@{[$ocnt||0]} bytes)"
	    unless $ocnt == $icnt;
	$want = $self->{addr};
	$got = $self->{bus}->{mode} == M_ASCII ? hex($tmp) : ord($tmp);
	if ($got != $want) {
	    die "Unexpected return from Modbus device (addr echo mismatch)"
	    }
	$buf .= $tmp;
	# Read the echoed command
	$ocnt = $self->_my_read($tmp, $icnt = 1 * $self->{bus}->{mode});
	die "Unexpected return from Modbus device (@{[$ocnt||0]} bytes)"
	    unless $ocnt == $icnt;
	$buf .= $tmp;
	$want = $fn;
	$got = $self->{bus}->{mode} == M_ASCII ? hex($tmp) : ord($tmp);
	if ($got != $want) {
	    # Error handling...
	    if (($got & 0x7f) == $want) {
		my $err;
		$ocnt = $self->_my_read($tmp, $icnt = 1 * $self->{bus}->{mode});
		die "Unexpected return from Modbus device (@{[$ocnt||0]} bytes)"
		    unless $ocnt == $icnt;
		$buf .= $tmp;
		$got = $self->{bus}->{mode} == M_ASCII ? hex($tmp) : ord($tmp);
		$ocnt = $self->_my_read($tmp, $icnt = 2);
		die "Unexpected return from Modbus device (@{[$ocnt||0]} bytes)"
		    unless $ocnt == $icnt;
		$buf .= $tmp;
		if ($self->{bus}->{mode} == M_ASCII) {
		    if (_verify_lrc($buf)) {
			$err = hex(substr($buf, 4, 2));
			warn "Modbus Exception: $exception[$err]";
			}
		    else {
			warn "Bad error LRC from device\n";
			}
		    }
		else {
		    if (_verify_crc($buf)) {
			$err = ord(substr($buf, 2, 1));
			warn "Modbus Exception: $exception[$err]";
			}
		    else {
			warn "Bad error CRC from device\n";
			}
		    }
		}
	    else {
		die "Unexpected return from Modbus device (cmd echo mismatch)"
		}
	    return undef;
	    }
	# Read the byte count
	$ocnt = $self->_my_read($tmp, $icnt = 1 * $self->{bus}->{mode});
	if ($self->{bus}->{mode} == M_ASCII) {
	    $nbytes = hex($tmp);
	    }
	else {
	    $nbytes = ord($tmp);
	    }
	die "Odd byte count returned from device\n" if $fn > 0x3 && $nbytes & 1;
	$buf .= $tmp;
	if ($this_set[0] < 20000) {
	    my $nval = @this_set;
	    my $idx = $base + $start + 1;
	    my ($bit, $byte, $nbits);
	    for (1..$nbytes) {
		$ocnt = $self->_my_read($tmp, $icnt = 1 * $self->{bus}->{mode});
		die "Didn't get byte $_ from device\n"	unless $ocnt == $icnt;
		$buf .= $tmp;
		#
		# All sorts of endian issues here.  The MSB contains the first
		# bit, but if there are fewer than 8 bits, they are 0 padded
		# to the left.  What idiot designed this?
		#
		if ($self->{bus}->{mode} == M_ASCII) {
		    $byte = hex($tmp);
		    }
		else {
		    $byte = ord($tmp);
		    }
		$bit = 0x01;
		$nbits = $nval > 8 ? 8 : $nval;
		for (1..$nbits) {
		    push @retval, ($regs->{$idx++} = ($byte & 1));
		    $byte >>= 1;
		    $nval--;
		    }
		}
	    }
	elsif ($this_set[0] > 30000 && $this_set[0] < 50000) {
	    # Read each 16-bit return value
	    my $val;
	    for (1..$nbytes/2) {
		$ocnt = $self->_my_read($tmp, $icnt = 2 * $self->{bus}->{mode});
		die "Didn't get @{[$ocnt||0]} != 2 bytes for data element $_ from device\n"
		    unless $ocnt == $icnt;
		$buf .= $tmp;
		if ($self->{bus}->{mode} == M_ASCII) {
		    $val = hex($tmp);
		    }
		else {
		    $val = unpack('n', $tmp);
		    }
		push @retval, $regs->{$_ + $base + $start - 1} = $val;
		}
	    }
	else {
	    die "Shouldn't get here!";
	    }
	# Finally, read the CRC/LRC and verify correctness
	$ocnt = $self->_my_read($tmp, 2);
	die "Didn't get @{[$ocnt||0]} != 2 bytes for CRC/LRC from device\n"
	    unless $ocnt == 2;
	$buf .= $tmp;
	if ($self->{bus}->{mode} == M_ASCII) {
	    warn "Bad LRC from device\n"	unless _verify_lrc($buf);
	    }
	else {
	    warn "Bad CRC from device\n"	unless _verify_crc($buf);
	    }
	}
    if (wantarray) {
	return @retval;
	}
    else {
	return $regs;
	}
    }

=item $unit->write()

The I<write> method is called with a hash table or a reference to hash table
as a paremeter (where the keys of the hash are the addresses to write, and the
values of the hash are written to the corresponding addresses).

    $unit->write(6 => 1, 8 => 0, 2007 => 10, 2008 => 2);
    %hash = (6 => 1, 8 => 0, 2007 => 10, 2008 => 2);
    $unit->write(%hash);
    $unit->write(\%hash);

The API for the I<write> method does not distinguish between ModBus Coils or
Holding Registers.  It makes the necessary ModBus calls to get all of them to
work, even if they are mixed in a single invocation of the I<write> method.

General Reference registers are not presently supported, neeither are Mask
Write nor combined Read/Write functions - ask and ye shall receive, though...

=cut

sub write {
    my $self = shift;
    my (@this_set, @retval, @regs, %regs, $base, $fn, $start, $cmd, $resp,
	$tally, $icnt, $ocnt);

    die "You must write to a device (or broadcast), not a modbus\n"
	unless defined $self->{addr};

    if (@_ == 1 && ref $_[0] eq "HASH") {
	%regs = %{ $_[0] };
	}
    else {
	%regs = @_;
	}

    @regs = sort {$a <=> $b} keys %regs;
    while (@regs) {
	# Collect adjacent registers into a set to read...
	@this_set = ();
	push @this_set, shift @regs;
	$tally = 1;
	CLUMP: while (@regs) {
	    last CLUMP if $regs[0] != $this_set[-1] + 1;  # Must be adjacent
	    last CLUMP if ++$tally > $self->{clump};	  # Limit clump size
	    push @this_set, shift @regs;
	    }
	if ($this_set[0]  > 0 && $this_set[0] < 10000) {
	    $base = 00001;
	    $start = $this_set[0] - $base;
	    if (@this_set == 1) {
		$fn = 0x05;
		$cmd = pack('ccnn', $self->{addr}, $fn, $start,
		    $regs{$this_set[0]} ? 0xff00 : 0x0000);
		$resp = $cmd;
		}
	    else {
		my ($bit, $byte, @subset);
		$fn = 0x0f;
		$cmd = pack('ccnn', $self->{addr}, $fn, $start,
		    scalar(@this_set));
		$resp = $cmd;
		$cmd .= pack('c', int((@this_set+7)/8));	# Byte cnt
		while (@subset = splice(@this_set, 0, 8)) {
		    #
		    # All sorts of endian issues here.  The MSB contains the
		    # first bit, but if there are fewer than 8 bits, they are
		    # 0 padded to the left.  What idiot designed this?
		    #
		    $byte = 0;
		    $bit = 0x01;
		    for my $n (@subset) {
			$byte |= $regs{$n} ? $bit : 0;
			$bit <<= 1;
			}
		    $cmd .= pack('c', $byte);
		    }
		}
	    }
	elsif ($this_set[0] > 40000 && $this_set[0] < 50000) {
	    $base = 40001;
	    $start = $this_set[0] - $base;
	    if (@this_set == 1) {
		$fn = 0x06;
		$cmd = pack('ccnn', $self->{addr}, $fn, $start,
		    $regs{$this_set[0]});
		$resp = $cmd;
		}
	    else {
		$fn = 0x10;
		$cmd = pack('ccnn', $self->{addr}, $fn, $start,
		    scalar(@this_set));
		$resp = $cmd;
		$cmd .= pack('c', @this_set * 2);
		for my $n (@this_set) {
		    $cmd .= pack('n', $regs{$n});
		    }
		}
	    }
	else {
	    die "I don't know how to write registers like $this_set[0]\n";
	    }
	if ($self->{bus}->{mode} == M_ASCII) {
	    $cmd =~ s/(.)/sprintf "%02x", ord($1)/ges;
	    _append_lrc($cmd);
	    _append_lrc($resp);
	    $cmd = ":$cmd\r\n";
	    if ($self->{bus}->{debug}) {
		print STDERR "Modbus::Client Writing: $cmd";
		}
	    }
	else {
	    _append_crc($cmd);
	    _append_crc($resp);
	    if ($self->{bus}->{debug}) {
		print STDERR "Modbus::Client Writing: ";
		for (0..length($cmd)-1) {
		    printf STDERR "%02x", ord(substr($cmd,$_,1));
		    }
		print STDERR "\n";
		}
	    }
	syswrite($self->{fh}, $cmd);
	my ($buf, $nbytes, $err);
	# Read the echoed address and command
	$ocnt = $self->_my_read($buf, $icnt = length($resp));
	if ($ocnt != $icnt || $buf ne $resp) {
	    if ($self->{bus}->{mode} == M_ASCII) {
		if ($self->{bus}->{debug}) {
		    print STDERR "Modbus::Client Expected: $resp\n";
		    print STDERR "Modbus::Client Got     : $buf\n";
		    }
		if (_verify_lrc($buf)) {
		    $err = hex(substr($buf, 4, 2));
		    warn "Modbus Exception: $exception[$err]";
		    }
		else {
		    warn "Bad error LRC from device\n";
		    }
		}
	    else {
		if ($self->{bus}->{debug}) {
		    print STDERR "Modbus::Client Expected: ";
		    for (0..length($resp)-1) {
			printf STDERR "%02x", ord(substr($resp,$_,1));
			}
		    print STDERR "\n";
		    print STDERR "Modbus::Client Got     : ";
		    for (0..length($buf)-1) {
			printf STDERR "%02x", ord(substr($buf,$_,1));
			}
		    print STDERR "\n";
		    }
		if (_verify_crc($buf)) {
		    $err = ord(substr($buf, 2, 1));
		    warn "Modbus Exception: $exception[$err]";
		    }
		else {
		    warn "Bad error CRC from device\n";
		    }
		}
	    return undef;
	    }
	}
    }

# Yes, I know that there are CRC routines in the CPAN - and it seems that
# the ModBus CRC uses a non-standard polynomial value.  So... here you go.

sub _crc {
    my $str = shift;
    my $crc = 0xFFFF;
    my ($chr, $lsb);

    for my $i (0..length($str)-1) {
	$chr = ord(substr($str, $i, 1));
	$crc ^= $chr;
	for (1..8) {
	    $lsb = $crc & 1;
	    $crc >>= 1;
	    $crc ^= 0xA001	if $lsb;
	    }
	}
    return $crc;
    }

sub _append_crc {
    my $crc = _crc($_[0]);

    $_[0] .= pack 'v', $crc;
    }

sub _verify_crc {
    my $str = shift;
    my $crc = unpack('v', substr($str, -2));
    substr($str, -2) = "";

    return $crc == _crc($str);
    }

sub _lrc {
    my $str = shift;
    my $lrc = 0;

    for my $char (split //, $str) {
	$lrc += ord($char);
	}
    return sprintf "%02x", -$lrc & 0xFF;
    }

sub _append_lrc {
    my $lrc = _lrc($_[0]);

    $_[0] .= $lrc;
    }

sub _verify_lrc {
    my $str = shift;
    my $lrc = substr($str, -2);
    substr($str, -2) = "";

    return $lrc eq _lrc($str);
    }

=item $clump_size = $self->clump([$new_clump_size]))

The clump method is used to set the number of elements that may be read or
written in a single operation.  Note that read() and write() will always
operate on as many elements as are specified, but to reduce the possibility
of errors, it will break them up into clumps.  This routine specifies the
maximum size of such a clump.  The initial value is 125 (as implied by the
Modbus spec), and may in any event not exceed 127 (since the byte count in
returned data is stored in an 8 bit field, and 127 16-bit registers is 254
bytes).

Setting the clump size on a device changes the behavior of that device only.
Setting the clump size on a modbus changes the behavior of all devices that
are created I<after> the change (that is, there is only partial inheritance).

=cut

sub clump {
    my ($self, $clump) = @_;

    if (defined $clump) {
	if ($clump < 1) {
	    $self->{clump} = 32;
	    }
	elsif ($clump > 127) {
	    $self->{clump} = 127;
	    }
	else {
	    $self->{clump} = $clump;
	    }
	}
    return $self->{clump};
    }

=item $mode = $self->mode([M_RTU | M_ASCII]))

The mode method is used to set the communication mode to the device.  The
two choices are M_ASCII and M_RTU (both are constants exported by the
Modbus::Client package, the default mode is M_RTU).  ASCII mode is more
readable (for debugging), RTU mode is faster (using fewer bytes).  The method
returns the current mode.

Setting the mode on a device or an a modbus changes the mode for all devices
on the bus (since according to the spec, all devices must comunicate using the
same mode).

=cut

sub mode {
    my ($self, $mode) = @_;

    if (defined $mode) {
	if ($mode == M_ASCII) {
	    $self->{bus}->{mode} = M_ASCII;
	    }
	elsif ($mode == M_RTU) {
	    $self->{bus}->{mode} = M_RTU;
	    }
	else {
	    warn "Unknown value for mode ($mode) ignored";
	    }
	}
    return $self->{bus}->{mode};
    }


=item $mode = $self->debug(1 | 0))

The debug method is used to enable or disable communication debugging.

Setting debug mode on a device or an a modbus changes the mode for all devices
on the bus.

=cut

sub debug {
    my ($self, $debug) = @_;

    if (defined $debug) {
	$self->{bus}->{debug} = $debug;
	}
    return $self->{bus}->{debug};
    }

=back

=head1 AUTHOR

Daniel V. Klein E<lt>L<dan@klein.com>E<gt>

=head1 SEE ALSO

L<http://www.modbus.org/specs.php> for the complete Modbus specifications

=cut

'Another module by Daniel V. Klein <dan@klein.com>';
