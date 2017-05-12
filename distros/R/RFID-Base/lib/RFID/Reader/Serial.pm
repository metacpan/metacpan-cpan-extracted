package RFID::Reader::Serial;
use RFID::Reader qw(ref_tainted); $VERSION=$RFID::Reader::VERSION;
our @ISA = qw();

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004-2006 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Reader::Serial - Abstract base class for readers implemented over a serial connection.

=head1 SYNOPSIS

This is an abstract base class used for building an RFID Reader class
implemented over a TCP connection.  It provides the basic I/O methods
that an object based on L<RFID::Reader|RFID::Reader> will expect, and
generally a reader based on this class will simply inherit from it and
add a few details.  In other words, this class is fairly complete, and
you shouldn't have to add much to it to make it workable.

=head1 DESCRIPTION

=cut

use constant BAUDRATE => 115200;
use constant DATABITS => 8;
use constant STOPBITS => 1;
use constant PARITY => 'none';
use constant HANDSHAKE => 'none';
use constant DEFAULT_TIMEOUT => 30; # seconds

# This is small, but if it's larger reads will sometimes
# time out, and if it's zero we poll in a tight loop.
use constant STREAMLINE_BUFSIZE => 1; 
=head2 Constructor

=head3 new

This constructor accepts its parameters as a hash.  Any unrecognized
arguments are intrepeted as parameters to the L<set|RFID::Reader/set>
method.

The following parameters are accepted:

=over 4

=item Port

The serial port object that communication should take place over.  The
object should be compatible with
L<Win32::SerialPort|Win32::SerialPort>; the Unix equivalent is
L<Device::SerialPort|Device::SerialPort>.  You are responsible for
creating the serial port object.

=item Timeout

The maximum time to wait for a response from the reader, in seconds.

=item Baudrate

An integer specifying the speed at which communication should take
place.

=back

=cut

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;

    my(%p)=@_;

    $self->{com} = $p{Port}
        or die __PACKAGE__."::new requires argument 'Port'\n";
    delete $p{Port};
    $self->{timeout} = $p{Timeout}||$p{timeout}||DEFAULT_TIMEOUT;
    $self->{databits}=DATABITS;
    $self->{stopbits}=STOPBITS;
    $self->{parity}=PARITY;
    $self->{handshake}=HANDSHAKE;
    $self->{baudrate}=$p{Baudrate}||$p{baudrate}||BAUDRATE;

    $self->_init(%p);
    $self;
}

sub _init
{
    my $self = shift;

    $self->{com}->databits($self->{databits});
    $self->{com}->stopbits($self->{stopbits});
    $self->{com}->parity($self->{parity});
    $self->{com}->handshake($self->{handshake});

    if ($self->{baudrate} > 115200 && (ref($self->{com}) eq 'Win32::SerialPort'))
    {
	# This is a hack to work around an annoying bug in Win32::CommPort.
	$self->{com}->baudrate(115200);
	$self->{com}->{_N_BAUD}=$self->{baudrate};
    }
    else
    {
	$self->{com}->baudrate($self->{baudrate});
    }
    $self->{com}->write_settings 
	or die "No settings: $!\n";
    $self->{com}->user_msg(1);
    $self->{com}->error_msg(1);
}

sub _writebytes
{
    my $self = shift;
    my($data)=join("",@_);
    my $bytesleft = my $size = length($data);
    if (ref_tainted(\$data)) { die "Attempt to send tainted data to reader"; }
    my $start = time;
    while ($bytesleft > 0)
    {
	if ( (time - $start) > $self->{timeout})
	{
	    die "Write timeout.\n";
	}
	my $wb = $self->{com}->write($data)
	    or die "Write timeout.\n";
	substr($data,0,$wb,"");
	$bytesleft -= $wb;
    }
    $size;
}

sub _connected
{
    return $self->{com};
}

sub _readbytes
{
    my $self = shift;
    my($bytesleft)=@_;
    my $data = "";

    $self->{com}->read_const_time($self->{timeout}*1000);
    my $start = time;
    while($bytesleft > 0)
    {
	if ( (time - $start) > $self->{timeout})
	{
	    die "Read timeout.\n";
	}

	my($rb,$moredata)=$self->{com}->read($bytesleft);
	$bytesleft -= $rb;
	$data .= $moredata;
    }
    $data;
}

sub _readuntil
{
    my $self = shift;
    my($delim) = @_;

    my $started = time;
    
    my $com = $self->{com};
    $com->read_const_time($self->{timeout} * 1000);

    my $match;
    my $i = 0;
    $self->{com}->are_match($delim);
    while (!($match = $com->streamline(STREAMLINE_BUFSIZE)))
    {
      if ( (time - $started) >= $self->{timeout})
      {
	die "Timeout waiting for response\n";
      }
    }
    return $match;

}

=head1 SEE ALSO

L<RFID::Reader>, L<RFID::Reader::Serial>, L<Win32::SerialPort>,
L<Device::SerialPort>.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004-2006 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut

1;
