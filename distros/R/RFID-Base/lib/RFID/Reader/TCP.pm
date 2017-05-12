package RFID::Reader::TCP;
use RFID::Reader qw(ref_tainted); $VERSION=$RFID::Reader::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004-2006 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Reader::TCP - Abstract base class for RFID readers implemented over a TCP connection

=head1 SYNOPSIS

This is an abstract base class used for building an RFID Reader class
implemented over a TCP connection.  It provides the basic I/O methods
that an object based on L<RFID::Reader|RFID::Reader> will expect, and
generally a reader based on this class will simply inherit from it and
add a few details.  In other words, this class is fairly complete, and
you shouldn't have to add much to it to make it workable.

=head1 DESCRIPTION

=cut

use IO::Socket::INET;
use IO::Select;

=head2 Constructor

=head3 new

This constructor accepts all arguments to the constructor for
L<IO::Socket::INET|IO::Socket::INET>, and passes them along to it.
Any other settings are intrepeted as parameters to the
L<set|RFID::Alien::Reader/set> method.

Currently, the Timeout parameter is sometimes ignored.  That will be
fixed in the future.

=cut

sub new
{
    my $class = shift;
    my(%p)=@_;
    my $buf;

    my $self = {};
    bless $self,$class;

    # For IO::Socket::INET
    if ($p{timeout} && !$p{Timeout})
    {
	$p{Timeout}=$p{timeout};
    }

    $self->{_sock}=IO::Socket::INET->new(%p)
	or die "Couldn't create socket: $!\n";
    
    $self->{_select}=IO::Select->new($self->{_sock})
	or die "Couldn't create IO::Select: $!\n";

    # Clear out any gibberish that's waiting for us
    while ($self->{_select}->can_read(1))
    {
	($self->{_sock}->sysread($buf,8192));
	warn "Ignoring initial text '$buf'\n";
    }

    $self->_init(%p);

    $self;
}

sub _init
{
}

sub _readbytes
{
    my $self = shift;
    my($bytesleft)=@_;
    my $data = "";

    while($bytesleft > 0)
    {
	my $moredata;
	if ($self->{timeout})
	{
	    $self->{_select}->can_read($self->{timeout})
		or die "Read timed out.\n";
	}
	my $rb = $self->{_sock}->sysread($moredata,$bytesleft)
	    or die "Socket unexpectedly closed!\n";
	$bytesleft -= $rb;
	$data .= $moredata;
    }
    $data;
}

sub _readuntil
{
    my $self = shift;
    my($delim) = @_;

    local $/ = $delim;
    my $fh = $self->{_sock};
    defined(my $data = <$fh>)
	or die "Couldn't read from socket: $!\n";
    chomp($data);
    $data;
}

sub _writebytes
{
    my $self = shift;
    my $wb = join("",@_);
    if (ref_tainted(\$wb)) { die "Attempt to send tainted data to reader"; }
    if ($self->{timeout})
    {
	$self->{_select}->can_write($self->{timeout})
	    or die "Write timed out.\n";
    }
    $self->{_sock}->syswrite($wb);
}

sub _connected
{
    return $self->{_sock};
}

=head1 SEE ALSO

L<RFID::Reader>, L<RFID::Reader::Serial>, L<IO::Socket::INET>.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004-2006 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut

1;
