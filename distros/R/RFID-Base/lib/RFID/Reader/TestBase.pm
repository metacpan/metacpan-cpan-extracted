package RFID::Reader::TestBase;
use RFID::Reader qw(ref_tainted); $VERSION=$RFID::Reader::VERSION;
@ISA=();

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004-2006 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Reader::TestBase - Provide basic methods for writing an RFID reader test module

=head1 SYNOPSIS

Provides fake backend methods to test out L<RFID::Reader|RFID::Reader>
without having access to a real reader.

=cut


use IO::Select;
use IO::Handle;
use Carp;

sub _init
{
    my $self = shift;

    $self->{_readbuf}='';
    $self->{_writebuf}='';
    $self;
}

sub _add_output
{
    my $self = shift;
    $self->{_writebuf} .= join('',@_);
}

sub _writebytes
{
    my $self = shift;
    my $wb = join("",@_);
    if (ref_tainted(\$wb)) { die "Attempt to send tainted data to reader"; }
    $self->debug("WRITEBYTES: $wb\n");
    $self->{_readbuf} = $self->_process_input($self->{_readbuf}.$wb);
    return length($wb);
}

sub _readbytes
{
    my $self = shift;
    my($wantbytes)=@_;

    my $rb = substr($self->{_writebuf},0,$wantbytes,'');

    $self->debug("READBYTES: $rb\n");
    $rb;
}

sub _readuntil
{
    my $self = shift;
    my($delim)=@_;

    if ($self->{_writebuf} =~ s/^(.*?)$delim//s)
    {
	$self->debug("READUNTIL: $1\n");
	return $1;
    }
    else
    {
	croak "Attempt to read with no data!";
    }
}

sub run
{
    my $self = shift;
    my $readh = shift || IO::Handle->new_from_fd(fileno(STDIN),"r")
	or die "Couldn't get read filehandle: $!\n";
    my $writeh = shift || shift || IO::Handle->new_from_fd(fileno(STDOUT),"w")
	or die "Couldn't get write filehandle: $!\n";

    my $readsel = IO::Select->new($readh);
    my $writesel = IO::Select->new($writeh);
    
    while (1)
    {
	my($readable,$writable,undef) = IO::Select->select($readsel, $self->{_writebuf}?$writesel:undef, undef)
	    or last;
	if (@$readable)
	{
	    my $readbuf;
	    sysread($readable->[0],$readbuf,8192)
		or die "Couldn't read: $!\n";
	    # This is just for testing, so untaint it blindly.
	    $readbuf =~ /^(.*)$/s;
	    $self->_writebytes($1);
	}
	if (@$writable)
	{
	    my $wrote = syswrite($writable->[0],$self->{_writebuf})
		or die "Couldn't write: $!\n";
	    substr($self->{_writebuf},0,$wrote)='';
	}
    }
}

=head1 SEE ALSO

L<RFID::Reader>.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004-2006 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut

1;
