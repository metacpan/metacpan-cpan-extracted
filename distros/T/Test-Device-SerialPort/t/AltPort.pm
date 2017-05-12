package AltPort;
# Inheritance test for test3.t only

our $VERSION = '0.05';
require Exporter;
use Test::Device::SerialPort qw( :STAT :PARAM 0.05 );
our @ISA = qw( Exporter Test::Device::SerialPort );
our @EXPORT= qw();
our @EXPORT_OK= @Test::Device::SerialPort::EXPORT_OK;
our %EXPORT_TAGS = %Test::Device::SerialPort::EXPORT_TAGS;

my $in = BM_fCtsHold;
print "AltPort import=$in\n";
1;
