
package POCSAG::PISS;

=head1 NAME

POCSAG::PISS - A perl module for accessing the PISS modem

=head1 ABSTRACT

PISS is a simple protocol to talk to a synchronous POCSAG bit-banger
module. At concept level, much like KISS (Keep It Simple Stupid), but
for POCSAG instead of AX.25.

=head1 DESCRIPTION

Unless a debugging mode is enabled, all errors and warnings are reported
through the API (as opposed to printing on STDERR or STDOUT), so that
they can be reported nicely on the user interface of an application.

=head1 OBJECT INTERFACE

=cut

use strict;
use warnings;

use Device::SerialPort;

use Data::Dumper;

our $VERSION = '1.00';

#
# Configuration
#

=over

=item new(config)

Returns a new instance of the PISS modem driver. Usage:

 my $modem = new POCSAG::PISS(
    'serial' => '/dev/ttyUSB0',
    'serial_speed' => 9600,
    'max_tx_len' => 1000,
 );

=back

=cut

sub new 
{
	my $class = shift;
	my $self = bless { @_ }, $class;
	
	$self->{'initialized'} = 0;
	$self->{'name'} = 'POCSAG::PISS';
	$self->{'version'} = '1.0';
	
	# store config
	my %h = @_;
	$self->{'config'} = \%h;
	#print "settings: " . Dumper(\%h);
	
	$self->{'debug'} = ( $self->{'config'}->{'debug'} );
	
	$self->_debug('initializing');
	
	$self->_clear_errors();
	
	$self->{'piss_seq'} = 0;
	$self->{'max_tx_len'} = $self->{'config'}->{'max_tx_len'};
	
	# validate settings
	foreach my $k ('serial', 'serial_speed') {
		if (!defined $h{$k}) {
			return $self->_critical("Mandatory config setting '$k' not set!");
		}
	}
	
	return $self;
}

# report a critical error

sub _critical($$)
{
	my($self, $msg) = @_;
	
	warn $self->{'name'} . " - " . $msg . "\n";
	
	$self->{'last_err_code'} = 'CRITICAL';
	$self->{'last_err_msg'} = $msg;
	
	return;
}

# report an error

sub _error($$$)
{
	my($self, $code, $msg) = @_;
	
	if ($self->{'debug'}) {
		warn $self->{'name'} . " ERROR $code: $msg\n";
	}
	
	$self->{'last_err_code'} = $code;
	$self->{'last_err_msg'} = $msg;
	
	return 0;
}

# fetch errors

=over

=item get_error($modem)

Returns the error code and error message string for the last
error experienced.

my($code, $message) = $modem->get_error();

=back

=cut

sub get_error($)
{
	my($self) = @_;
	
	return ($self->{'last_err_code'}, $self->{'last_err_msg'});
}

=over

=item error_msg($modem)

Gets just the error message string for the last
error experienced. Good for 

$modem->open() || die "Failed to open modem: " . $modem->error_msg();

=back

=cut


sub error_msg($)
{
	my($self) = @_;
	
	return $self->{'last_err_msg'};
}

# clear the error flags

sub _clear_errors($)
{
	my($self) = @_;
	
	$self->{'last_err_code'} = 'ok';
	$self->{'last_err_msg'} = 'no error reported';
}

# report a debug log

sub _debug($$)
{
	my($self, $msg) = @_;
	
	return if (!$self->{'debug'});
	
	warn $self->{'name'} . " DEBUG $msg\n";
}

#
#### Serial port functions
#

sub _serial_readflush($)
{
	my($self) = @_;
	
	$self->_debug("serial_readflush start");
	
	while (1) {
		my $s = $self->{'port'}->read(100);
		$self->_debug("read: $s");
		last if ($s eq '');
	}
	
	$self->_debug("complete!");
}

=over

=item open()

Opens the serial device after locking it using a lock file in /var/lock,
sets serial port parameters, and flushes the input buffer by reading
whatever the modem has transmitted to us since we last read from the port.

The flushing part does take a couple of seconds, so be patient.

=back

=cut

sub open($)
{
	my($self) = @_;
	
	$self->_debug("opening serial");
	my $lockfile = $self->{'config'}->{'serial'};
	$lockfile =~ s/^.*\///;
	$lockfile = "/var/lock/LCK..$lockfile";
	my $port = new Device::SerialPort($self->{'config'}->{'serial'}, 0, $lockfile);
	if (!$port) {
		$self->_critical("Can't open serial port " . $self->{'config'}->{'serial'} . ": $!");
		return;
	}
	
	$self->{'port'} = $port;
	
	$port->databits(8);
	$port->baudrate($self->{'config'}->{'serial_speed'});
	$port->parity("none");
	$port->stopbits(1);
	$port->handshake("none");
	
	$port->read_char_time(0);
	$port->read_const_time(5000);
	
	if (!$port->write_settings) {
		$self->_critical("Can't write serial settings: $!");
		$self->close();
		return;
	}
	
	$self->_serial_readflush();
	
	return 1;
}

=over

=item close()

Closes the serial device.

=back

=cut

sub close($)
{
	my($self) = @_;
	
	$self->_debug("closing serial");
	$self->{'port'}->close || $self->_error("serial_err", "serial close failed: $!");
	undef $self->{'port'};
}

=over

=item keepalive()

Reopens the serial device, if needed, if it has been closed due to a error for example.

=back

=cut

sub keepalive($)
{
	my($self) = @_;
	
	#$self->_debug("serial keepalive...");
	
	if (!$self->{'port'}) {
		$self->open();
	}
}

sub _serial_write($$)
{
	my($self, $cmd) = @_;
	 
	my $len = length($cmd);
	my $wrote = $self->{'port'}->write($cmd);
	if (!$wrote) {
		$self->_error("serial_err", "Failed to write to serial port: $!");
		return;
	}
	
	if ($wrote != $len) {
		$self->_error("serial_err", "Write to serial port incomplete: wrote $wrote of $len");
		return;
	}
	
	return 1;
}



#
#### Actual PISS protocol commands
#

sub _piss_cmd($)
{
	my($self, $cmd) = @_;
	
	$self->_serial_write($cmd);
	
	$self->_debug("piss_cmd wrote cmd, reading...\n");
	my $timeout = 60;
	my $start_t = time();
	
	my $rbuf = '';
	while (1) {
		my $c = $self->{'port'}->read(1);
		if (!defined $c) {
			$self->_debug("piss_cmd read returned undefined");
		} else {
			$rbuf .= $c;
			
			while ($rbuf =~ s/(FAULT.*?)[\r\n]//s) {
				$self->_error("piss_fault", "PISS FAULT REPORTED: $1");
			}
			
			while ($rbuf =~ s/R\s+(.)\s+(\d+)\s+(\d+)[\r\n]//s) {
				$self->_debug("R id $1 len $2 maxlen $3");
				$self->{'max_tx_len'} = $3;
			}
			
			while ($rbuf =~ s/OK\s+(.)[\r\n]//s) {
				$self->_debug("Transmitted ok: $1");
			}
			
			while ($rbuf =~ s/ER\s+(.)\s+(.*?)[\r\n]//s) {
				$self->_error("piss_err", "PISS ERROR id $1: $2");
			}
		}
	
		last if ($rbuf =~ /\.[\n\r]+/s);
		if (time() - $start_t >= $timeout) {
			$self->_error("piss_tout", "piss_cmd timed out at $timeout s");
			return 0;
		}
	}
		
	$self->_debug("piss_cmd read: $rbuf");
	
	return 1;
}

=over

=item max_tx_len()

Returns the maximum length of a transmit buffer the modem is willing to take.
Depends on the available memory on the modem, and it's internal data set size.
Whatever this function returns, should be passed to POCSAG::Encode.

=back

=cut

sub max_tx_len($)
{
	my($self) = @_;
	
	return $self->{'max_tx_len'};
}

=over

=item brraaap($encoded)

Transmits an encoded message, as returned by POCSAG::Encode::generate().

=back

=cut

sub brraaap($$)
{
	my($self, $encoded) = @_;
	
	$self->{'piss_seq'}++;
	$self->{'piss_seq'} = 0 if ($self->{'piss_seq'} == 26);
	
	my $seqid = chr($self->{'piss_seq'} + 97);
	
	if (length($encoded) > $self->{'max_tx_len'}) {
		$self->_error("piss_toolong", "piss_send_msg: Too long message: " . length($encoded) . " is larger than maximum of " . $self->{'max_tx_len'});
		return;
	}
	
	my $cmd = "T" . $seqid . "1" . unpack('H*', $encoded) . "X";
	$self->_debug("piss_send_msg $cmd, length " . length($encoded));
	if (!$self->_piss_cmd($cmd)) {
		$self->_debug("piss_send_msg: piss_cmd failed: " . $self->error_msg());
		return;
	}
	
	$self->_debug("piss_send_msg done");
	
	return 1;
}

=over

=item close()

Closes the modem device. Can be reopened with open().

=back

=cut
