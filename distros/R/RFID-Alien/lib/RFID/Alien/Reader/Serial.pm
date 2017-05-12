package RFID::Alien::Reader::Serial;
use RFID::Alien::Reader; $VERSION=$RFID::Alien::Reader::VERSION;
use RFID::Reader::Serial;
@ISA = qw(RFID::Reader::Serial RFID::Alien::Reader);

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004-2006 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Alien::Reader::Serial - Implement L<RFID::Alien::Reader|RFID::Alien::Reader> over a serial link

=head1 SYNOPSIS

This class takes a serial port object and implements the Alien RFID
protocol over it.  It is based on L<RFID::Reader::Serial|RFID::Reader::Serial>, and it takes the same parameters as L<its constructor|RFID::Reader::Serial/new>.  All other parameters are passed along to the 
L<set method|RFID::Alien::Reader/set>

An example:

    use Win32::Serialport;
    use RFID::Alien::Reader::Serial;

    $com = Win32::SerialPort->new('COM1')
	or die "Couldn't open COM port 'COM1': $^E\n";

    my $reader = 
      RFID::Alien::Reader::Serial->new(Port => $com,
				       AntennaSequence => [0,1,2,3])
        or die "Couldn't create reader object\n";

    $reader->set(PersistTime => 0,
                 AcquireMode => 'Inventory') == 0
        or die "Couldn't set reader properties\n";

    my @tags = $reader->readtags();
    foreach my $tag (@tags)
    {
	print "I see tag ",$tag->id,"\n";
    }

=head1 DESCRIPTION

This class is built on top of
L<RFID::Alien::Reader|RFID::Alien::Reader>, and
L<RFID::Reader::Serial|RFID::Reader::Serial>.

=cut

use constant BAUDRATE => 115200;
use constant DATABITS => 8;
use constant STOPBITS => 1;
use constant PARITY => 'none';
use constant HANDSHAKE => 'none';
use constant DEFAULT_TIMEOUT => 30; # seconds

=head2 Constructor

=head3 new

Creates a new object.  This constructor accepts all arguments to the
constructors for L<RFID::Alien::Reader|RFID::Alien::Reader> and
L<RFID::Reader::Serial|RFID::Reader::Serial>, and passes them along to
both constructors.  Any other settings are intrepeted as parameters to
the L<set|RFID::Alien::Reader/set> method.

=cut

sub new
{
    my $class = shift;
    my(%p)=@_;
    
    my $self = {};

    $self->{com} = $p{Port}
        or die __PACKAGE__."::new requires argument 'Port'\n";
    delete $p{Port};
    $self->{timeout} = $p{Timeout}||$p{timeout}||DEFAULT_TIMEOUT;

    $self->{databits}=DATABITS;
    $self->{stopbits}=STOPBITS;
    $self->{parity}=PARITY;
    $self->{handshake}=HANDSHAKE;
    $self->{baudrate}=$p{Baudrate}||$p{baudrate}||BAUDRATE;

    bless $self,$class;
    
    # Initialize everything.
    foreach my $parent (__PACKAGE__,@ISA)
    {
	if (my $init = $parent->can('_init'))
	{
	    $init->($self,%p);
	}
    }
    
    # Now clear out any data waiting on the serial port.
    $self->{com}->purge_all;
    $self->_writebytes("\x0d\x0a");
    my($rb,$data);
    do
    {
	$self->{com}->read_const_time(250);
	($rb,$data)=$self->{com}->read(4096);
	$self->debug("Discarding $rb bytes of junk data: '$data'\n");
    } while ($rb);
    $self->{com}->purge_all;
    
    $self;
}


=head1 SEE ALSO

L<RFID::Alien::Reader>, L<RFID::Reader::Serial>,
L<RFID::Alien::Reader::TCP>, L<http://whereabouts.eecs.umich.edu/code/rfid-perl/>.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004-2006 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut



1;
