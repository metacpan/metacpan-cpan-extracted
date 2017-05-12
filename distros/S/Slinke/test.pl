# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Slinke;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $slinke = new Slinke;
if ( $slinke ) { print "ok 2\n"; }
else           { print "not ok 2\n"; }

# read the firmware version
my $data = $slinke->requestFirmwareVersion();
if ( defined $data ) { print "ok 3\n"; }
else                 { print "not ok 3\n"; }

# read the serial number
$data = $slinke->requestSerialNumber();
if ( defined $data ) { print "ok 4\n"; }
else                 { print "not ok 4\n"; }

# read the baud rate
$data = $slinke->requestBaud();
if ( defined $data ) { print "ok 5\n"; }
else                 { print "not ok 5\n"; }

# try disabling ports
my $allSuccess = 1;
foreach my $i qw( PORT_SL0 PORT_SL1 PORT_SL2 PORT_SL3 PORT_IR PORT_PAR PORT_SYS ) {
    $data = $slinke->disablePort( $i );
    $allSuccess = 0 if ( !defined $data );
}
if ( $allSuccess ) { print "ok 6\n"; }
else               { print "not ok 6\n"; }

# try enabling ports
$allSuccess = 1;
foreach my $i qw( PORT_SL0 PORT_SL1 PORT_SL2 PORT_SL3 PORT_IR PORT_PAR PORT_SYS ) {
    $data = $slinke->enablePort( $i );
    $allSuccess = 0 if ( !defined $data );
}
if ( $allSuccess ) { print "ok 7\n"; }
else               { print "not ok 7\n"; }

# read the IR Sampling Period
$data = $slinke->requestIRSamplingPeriod();
if ( defined $data ) { print "ok 8\n"; }
else                 { print "not ok 8\n"; }

# read the IR Carrier Frequency
$data = $slinke->requestIRCarrier();
if ( defined $data ) { print "ok 9\n"; }
else                 { print "not ok 9\n"; }

# read the IR Timeout Period
$data = $slinke->requestIRTimeoutPeriod();
if ( defined $data ) { print "ok 10\n"; }
else                 { print "not ok 10\n"; }

# read the IR Minimum Message Length
$data = $slinke->requestIRMinimumLength();
if ( defined $data ) { print "ok 11\n"; }
else                 { print "not ok 11\n"; }

# read the IR Transmit Ports
$data = $slinke->requestIRTransmitPorts();
if ( defined $data ) { print "ok 12\n"; }
else                 { print "not ok 12\n"; }

# read the IR Receive Ports
$data = $slinke->requestIRReceivePorts();
if ( defined $data ) { print "ok 13\n"; }
else                 { print "not ok 13\n"; }

# read the IR Receive Polarity
$data = $slinke->requestIRReceivePorts();
if ( defined $data ) { print "ok 14\n"; }
else                 { print "not ok 14\n"; }

# read the IR Routing Table
my @data = $slinke->requestIRRoutingTable();
if ( $#data >= 0 ) { print "ok 15\n"; }
else               { print "not ok 15\n"; }

# read the Parallel Port Handshaking
$data = $slinke->requestHandshaking();
if ( defined $data ) { print "ok 16\n"; }
else                 { print "not ok 16\n"; }

# read the Parallel Port Direction
$data = $slinke->requestDirection();
if ( defined $data ) { print "ok 17\n"; }
else                 { print "not ok 17\n"; }

# try sampling the parallel port
$slinke->sampleParPort();
$data = $slinke->requestInput;
if ( defined $data && $data->{ PORT } eq "PORT_PAR" ) { print "ok 18\n"; }
else                                                  { print "not ok 18\n"; }

# Test changing of values
# try changing the baud rate
my $oldRate = $slinke->requestBaud;
my $sampleRate = 19200;
$data = $slinke->setBaud( $sampleRate );
if ( defined $data && $data == $sampleRate ) { print "ok 19\n"; }
else                                         { print "not ok 19\n"; }
$slinke->setBaud( $oldRate );

# try changing the IR Sampling Period
$oldRate = $slinke->requestIRSamplingPeriod;
$sampleRate = 120 / 1e6;
$data = $slinke->setIRSamplingPeriod( $sampleRate );
if ( defined $data && $data == $sampleRate ) { print "ok 20\n"; }
else                                         { print "not ok 20\n"; }
$slinke->setIRSamplingPeriod( $oldRate );

# try setting the IR Carrier Frequency;
$oldRate = $slinke->requestIRCarrier();
$sampleRate = 38000;
$data = $slinke->setIRCarrier( $sampleRate );
if ( defined $data && abs( $data - $sampleRate ) < 500 ) { print "ok 21\n"; }
else                                                     { print "not ok 21\n"; }
$data = $slinke->setIRCarrier( $oldRate );

# try setting the IR Timeout Period
$oldRate = $slinke->requestIRTimeoutPeriod();
$sampleRate = 400;
$data = $slinke->setIRTimeoutPeriod( $sampleRate );
if ( defined $data && $data == $sampleRate ) { print "ok 22\n"; }
else                                         { print "not ok 22\n"; }
$slinke->setIRTimeoutPeriod( $oldRate );

# try setting the IR Minimum Message Length
$oldRate = $slinke->requestIRMinimumLength();
$sampleRate = 8;
$data = $slinke->setIRMinimumLength( $sampleRate );
if ( defined $data && $data == $sampleRate ) { print "ok 23\n"; }
else                                         { print "not ok 23\n"; }
$slinke->setIRMinimumLength( $oldRate );

# try setting the IR Transmit Ports
$oldRate = $slinke->requestIRTransmitPorts();
$allSuccess = 1;
foreach my $i ( 0..7 ) {
    $sampleRate = 1 << $i;
    $slinke->setIRTransmitPorts( $sampleRate );
    $data = $slinke->requestIRTransmitPorts();
    $allSuccess = 0 if ( !defined $data || $data != $sampleRate );
}
if ( $allSuccess ) { print "ok 24\n"; }
else               { print "not ok 24\n"; }
$slinke->setIRTransmitPorts( $oldRate );

# try setting the IR Receive Ports
$oldRate = $slinke->requestIRReceivePorts();
$allSuccess = 1;
foreach my $i ( 0..7 ) {
    $sampleRate = 1 << $i;
    $data = $slinke->setIRReceivePorts( $sampleRate );
    $allSuccess = 0 if ( !defined $data || $data != $sampleRate );
}
if ( $allSuccess ) { print "ok 25\n"; }
else               { print "not ok 25\n"; }
$slinke->setIRReceivePorts( $oldRate );

# try setting the IR Polarity
$oldRate = $slinke->requestIRPolarity();
$allSuccess = 1;
foreach my $i ( 0..7 ) {
    $sampleRate = 1 << $i;
    $data = $slinke->setIRPolarity( $sampleRate );
    $allSuccess = 0 if ( !defined $data || $data != $sampleRate );
}
if ( $allSuccess ) { print "ok 26\n"; }
else               { print "not ok 26\n"; }
$slinke->setIRPolarity( $oldRate );

# try setting the IR Routing Table
my @oldData = $slinke->requestIRRoutingTable();
my @sampleData = ( 0x10, 38000, 0x10, 38000, 0x10, 38000, 0x10, 38000,
		   0x10, 38000, 0x10, 38000, 0x10, 38000, 0x10, 38000 );
@data = $slinke->setIRRoutingTable( @sampleData );
$allSuccess = 1;
if ( $#data >= 0 ) {
    for ( my $i=0; $i <= $#data; $i+=2 ) {
	$allSuccess = 0 if ( $data[$i] != $sampleData[$i] );
    }
    for ( my $i=1; $i <= $#data; $i+=2 ) {
	$allSuccess = 0 if ( abs( $data[$i] - $sampleData[$i] ) > 500.0 );
    }
}
else {
    $allSuccess = 0;
}
if ( $allSuccess ) { print "ok 27\n"; }
else               { print "not ok 27\n"; }
@data = $slinke->setIRRoutingTable( @oldData );

# try setting the Parallel Port Handshaking
$oldRate = $slinke->requestHandshaking();
$sampleRate = 0x01;
$data = $slinke->setHandshaking( $sampleRate );
if ( defined $data && $data == $sampleRate ) { print "ok 28\n"; }
else                                         { print "not ok 28\n"; }
$slinke->setHandshaking( $oldRate );

# try setting the Parallel Port Direction
$oldRate = $slinke->requestDirection();
$sampleRate = 0x80;
$data = $slinke->setDirection( $sampleRate );
if ( defined $data && $data == $sampleRate ) { print "ok 29\n"; }
else                                         { print "not ok 29\n"; }
$slinke->setDirection( $oldRate );
