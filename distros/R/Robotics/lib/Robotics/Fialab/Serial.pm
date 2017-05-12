package Robotics::Fialab::Serial;
# vim:set ai shiftwidth=4 tabstop=4 expandtab:

use warnings;
use strict;

use Moose;
use Carp;

use Hardware::PortScanner;

extends 'Robotics::Fialab::Microsia';

# This module is not meant for direct inclusion.
# Use it "with" Fialab::Microsia.

my $COMPORT;
my $Debug = 1;

my @Serialnames = (
    "/dev/tty.usbserial-A6007XgT",
    "/dev/tty.usbserial-A6007Xyz",
    "/dev/ttyUSB0",
    "/dev/ttyUSB1"
);

has 'attached' => ( is => 'rw', isa => 'Bool' );
has 'last_reply' => ( is => 'rw', isa => 'Str' );
has 'object' => ( is => 'ro', isa => 'Robotics::Fialab' );
has 'SERIALDEV' => ( is => 'rw' );
has 'PORTS' => ( is => 'rw', isa => 'Maybe[ArrayRef]' );
has 'PORTSREF' => ( is => 'rw', isa => 'Maybe[HashRef]' );

has 'WRITE_DELAY' => ( is => 'rw', isa => 'Maybe[Int]', default => 0 );
has 'WRITE_ADDRESS' => ( is => 'rw', isa => 'Maybe[Str]');

=head1 NAME

Robotics::Fialab::Serial - (Internal module)
Software-to-Serial interface for Fialab Serial or USB-Serial on Unix/Win32
for controlling robotics hardware

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';

=head1 SYNOPSIS

Serial and USB-Serial software interface support for Robotics::Fialab.  
In Perl Robotics environment, the Robotics
modules use this module to send hardware commands
through a Serial port to the physical hardware.

This module is only useful in the framework of other Robotics
modules.  It probably should not be used on it's own.

=head1 EXPORT


=head1 FUNCTIONS

=head2 new

=head1 FUNCTIONS

=head2 probe

Probe the local machine for a Serial port to
communicate with as a software-hardware interface.

Finds the port only, does not find hardware (look at hardware modules
for that part).

Returns:

=item  Hash, with key:value as follows:  
key="Fialab-Microsia", 
value="not-started:name:token"  or "ok:name:token"
where name is the application-usable alias to use
for new()'s "unit" parameter, and token is an internal
reference for low level software.


=head2 open

(Internal function) Do not call

Open communication to Serial software<->hardware interface

=cut

sub probe {
    my $class = shift;
    my %found;
    
	my $serial = Hardware::PortScanner->new();
	
	my $num = $serial->scan_ports(
		BAUD => [ 9600 ],
        SETTING => [ '8N1' ],
        TEST_STRING => "/1Q/r",
       	VALID_REPLY_RE => '[\d]' );
	
	if ($num) {
		warn "Found Fialab Microsia\n";
		# TODO Enhance this to return multiple devs with enumerated names
		my $index_name = "0";
		my $portname = $serial->port_name();
		$found{"Microsia"} = "ok";
		$found{"Microsia"} .= ",Robotics::Fialab::Microsia";
		$found{"Microsia"} .= ",microsia$index_name,port=$portname";
	}
	else {
		#$found{"Fialab-Serial"} .= "network,Robotics::Fialab::Microsia,microsia0";
	}
	
	# Look for USB-Serial tty devices
	my $portlist;
    for my $name (@Serialnames) {
        if (-e $name) {
            # found? 
            $portlist .= $name. " ";
        } 
    }
    if ($portlist) { 
        $portlist =~ s/\s*$//;
        $found{"Microsia"} = "ok";
        $found{"Microsia"} .= ",Robotics::Fialab::Microsia";
        $found{"Microsia"} .= ",microsia0,port=$portlist,option=svpe";
    }
    
	return \%found;
}

sub BUILD { 
    my ($self) = shift;
    
    # This 'new' will open multiple ports in a port list
    my @portargs = grep(/port=/, split(",", $self->object()->connection));
    my $portlist = (split("=", $portargs[0]))[1];
    my @ports = split(" ", $portlist);
    my %porthash;
    
    die "no portargs" if !@portargs;
    die "no portlist from ".$self->object()->connection if !$portlist;
    
	my $isWin = 1 if ( $^O eq 'MSWin32' );
	my $quiet = 0;
	my $lockfile = "lock";
	my @serialobjs;
	
	if ($isWin) {
	    require Win32::SerialPort;
	    Win32::SerialPort::debug( "true", "True" ) if ($Debug);
	    for my $portname (@ports) { 
        	my $portobj = new Win32::SerialPort ($portname, $quiet, $lockfile)
    			|| confess "Can't open $portname: $!\n";
    		push(@serialobjs, $portobj);
	    }
	}
	else {
	    require Device::SerialPort;
	    #Device::SerialPort::debug( "true", "True" ) if ($Debug);
	    for my $portname (@ports) {
            warn "Opening Device::SerialPort $portname\n" if $Debug;
            my $portobj = new Device::SerialPort ($portname)
                || confess "Can't open $portname: $!\n";
            push(@serialobjs, $portobj);
	    }
	}
    # communication ok
    for my $portobj (@serialobjs) { 
        $portobj->databits(8);
        $portobj->baudrate(9600);
        $portobj->parity("none");
        $portobj->stopbits(1);
        $portobj->handshake("none");
                 
        $portobj->read_char_time(5);     # wait 5 msec for each character
        $portobj->read_const_time(500); # 1 second per unfulfilled "read" call
                
        if (0) {
            # test communication
        }
    }
    $self->PORTS( \@serialobjs );
    $self->attached( 0 );
    $self->WRITE_DELAY( 0 );
    $self->object()->HWTYPE( "svpe" );
}

sub attach {
    my ($self, %params) = @_;
    
    $self->attached( 1 );
    # Probe for Device status, set attached only if device present
    # Redundancy is indicated in manual
    my %porthash;
    $self->PORTSREF( \%porthash );
    my $found = 0;
    my $hwtype;
    for my $portobj (@{$self->PORTS()}) {
        my ($count, $saw);
        my $response = 0;
        ($count, $saw) = $portobj->read(200); # will read _up to_ N chars
        $portobj->write("/_ZR".chr(13));
        $portobj->write("/1QR".chr(13));
        ($count, $saw) = $portobj->read(200); # will read _up to_ N chars
        if (($count > 2) && ($saw =~ /\d+/i) && !($saw =~ /Bad command/i)) { 
            warn "ATTACH - ". __PACKAGE__. " Found syringe\n";
            $porthash{"syringe"} = $portobj;
            $portobj->alias( "syringe" );
            $hwtype .= 's';
            $found++;
            $response++;
        }
        ($count, $saw) = $portobj->read(200);
        $portobj->write("CP".chr(13));
        ($count, $saw) = $portobj->read(200);
        if (($count > 2) && ($saw =~ /\d+/i) && !($saw =~ /Bad command/i)) { 
            warn "ATTACH - ". __PACKAGE__. " Found valve\n";
            $porthash{"valve"} = $portobj;
            $portobj->alias( "valve" );
            $hwtype .= 'v';
            $found++;
            $response++;
        }
        if (!$response) { 
            carp "ATTACH - ERROR - No response from port; closing port";
            $portobj->close();
        }
    }
    if ($found < 1) {     
        warn "No response from device. NOT ATTACHED\n";
        $self->attached( 0 );
        
        #
        # TODO DEBUG ONLY 
        #warn "(forcing attach)";
        #$self->attached( 1 );
        return;
    }
    warn "ATTACHED ". __PACKAGE__. "\n";
    $self->object()->VERSION( 1 );
    $self->object()->HWTYPE( $hwtype );
    
    return;
}

sub write {
    my $self = shift;
    if (!$self->attached) { 
        carp "! attempted write when not Attached";
        return;
    }
    if ($self->attached) {
        my $data = shift;
        my $portref = $self->PORTSREF();
        carp 'no port in write' unless $portref;
        my $subdev = $self->WRITE_ADDRESS();
        carp 'no address in write' unless $subdev;
        if ($portref && $subdev) {
            my $portobj = $portref->{$subdev};
            if (!$portobj) { 
                carp "No such device connected: '$subdev'";
                return;
            }
            if ($Debug) { 
                use Data::HexDump::XXD qw( xxd );
                print "fialab-$subdev>". xxd($data). "\n";
            }
            $portobj->write($data);
            if ($self->WRITE_DELAY() > 0) { 
                warn __PACKAGE__. " delaying ".$self->WRITE_DELAY(). "\n";
                select(undef, undef, undef, $self->WRITE_DELAY()/1000);
                $self->WRITE_DELAY(0);
            }
        }
    }
}

sub read {
    my $self = shift;
    my $data;
    my $portref = $self->PORTSREF();
    my $subdev = $self->WRITE_ADDRESS();
    if ($portref && $subdev) {
        my $count;
        my $portobj = $portref->{$subdev};
        if (!$portobj) { 
            carp "No such device connected: '$subdev'";
            return;
        }
        ($count, $data) = $portobj->read(200);
    }
    if (!$data) { 
        return "";
    }
    
    if ($Debug) { 
        use Data::HexDump::XXD qw( xxd );
        print "fialab-$subdev< ". xxd($data). "\n";
    }

    return $data;
}        

sub close { 
    my ($self) = shift;
    $self->attached( 0 );  
    my $portsref = $self->PORTS();
    for my $portobj (@{$portsref}) { 
        $portobj->close();
    }    
    $self->PORTSREF( undef );
    $self->PORTS( undef );
    return;
}


=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-robotics at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics::Fialab::Serial


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Robotics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Robotics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Robotics>

=item * Search CPAN

L<http://search.cpan.org/dist/Robotics/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jonathan Cline.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Robotics::Fialab::Serial


__END__

