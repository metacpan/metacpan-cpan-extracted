package RFID::Matrics::Reader::Serial;
use RFID::Matrics::Reader; $VERSION=$RFID::Matrics::Reader::VERSION;
use RFID::Reader::Serial;
use Exporter;
@ISA = qw(RFID::Reader::Serial RFID::Matrics::Reader Exporter);
@EXPORT_OK = @RFID::Matrics::Reader::EXPORT_OK;
%EXPORT_TAGS = %RFID::Matrics::Reader::EXPORT_TAGS;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Matrics::Reader::Serial - Implement L<RFID::Matrics::Reader|RFID::Matrics::Reader> over a serial link

=head1 SYNOPSIS

This class takes a serial port object and implements the Matrics RFID
protocol over it.  This object is based on
L<RFID::Reader::Serial|RFID::Reader::Serial>, which should be
consulted for additional information.

An example:

    use Win32::Serialport;
    use RFID::Matrics::Reader::Serial;

    $com = Win32::SerialPort->new($opt{c})
	or die "Couldn't open COM port '$opt{c}': $^E\n";

    my $reader = 
      RFID::Matrics::Reader::Serial->new(Port => $com,
				         Node => 4,
					 Antenna => 1)
        or die "Couldn't create reader object";

=head1 DESCRIPTION

This class is built on top of
L<RFID::Matrics::Reader|RFID::Matrics::Reader>, and uses
L<RFID::Reader::Serial|RFID::Reader::Serial> to implement the
underlying setup, reading, and writing functions.

=cut

use RFID::Matrics::Reader qw(:ant);
use Carp;

use constant BAUDRATE => 230400;
use constant DATABITS => 8;
use constant STOPBITS => 1;
use constant PARITY => 'none';
use constant HANDSHAKE => 'none';
use constant DEFAULT_TIMEOUT => 2000; #ms

=head2 Constructor

=head3 new

This creates a new
L<RFID::Matrics::Reader::Serial|RFID::Matrics::Reader::Serial> object.
All parameters are simply sent along to either
L<the RFID::Reader::Serial Constructor|RFID::Reader::Serial/new> 
or L<the set method|Matrics::Reader/set>.

=cut

sub new
{
    my $class = shift;
    my(%p)=@_;
    
    my $self = {};

    $self->{com} = $p{Port}||$p{comport}
        or croak __PACKAGE__."::new requires argument 'Port'\n"; 
    $self->{timeout} = $p{Timeout}||$p{timeout}||DEFAULT_TIMEOUT;
   
    $self->{databits}=DATABITS;
    $self->{stopbits}=STOPBITS;
    $self->{parity}=PARITY;
    $self->{handshake}=HANDSHAKE;
    $self->{baudrate}=$p{Baudrate}||$p{baudrate}||BAUDRATE;

    bless $self,$class;

    # Initialize everything.
    foreach my $parent (@ISA)
    {
	if (my $init = $parent->can('_init'))
	{
	    $init->($self,%p);
	}
    }

    $self;
}

=head1 SEE ALSO

L<RFID::Matrics::Reader>, L<RFID::Matrics::Reader::TCP>,
L<RFID::Reader::Serial>, L<Win32::SerialPort>, L<Device::SerialPort>,
L<http://www.eecs.umich.edu/~wherefid/code/rfid-perl/>.

=head1 AUTHOR

Scott Gifford <gifford@umich.edu>, <sgifford@suspectclass.com>

Copyright (C) 2004 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut

1;
