package Net::Bluetooth;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;
require Exporter;
require DynaLoader;
require 5.008;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(get_remote_devices sdp_search);
$VERSION = '0.41';
bootstrap Net::Bluetooth $VERSION;

_init();

END { _deinit(); }



sub newsocket {
my $class = shift;
my $proto = shift;
my $client = shift;
my $addr = shift;
my $self = {};

	return if($proto !~ /^RFCOMM$|^L2CAP$/i);

	$self->{PROTO} = $proto;

	#### test this
	if(defined($client) && defined($addr)) {
		$self->{SOCK_FD} = $client;
		$self->{ADDR} = $addr;
	}

	else {
		my $sock = _socket($proto);
		return if($sock < 0);
		$self->{SOCK_FD} = $sock;
	}

	bless($self, $class);
	return $self;
}
                                                                                                                      

sub connect {
my $self = shift;
my $addr = shift;
my $port = shift;

	return -1 if(_connect($self->{SOCK_FD}, $addr, $port, $self->{PROTO}) < 0);

	$self->{ADDR} = $addr;
	$self->{PORT} = $port;

	return 0;
}


sub _debug {
my $self = shift;
	print "addr: $self->{ADDR}\n";
	print "sock: $self->{SOCK_FD}\n";
	print "proto: $self->{PROTO}\n";
}


sub bind {
my $self = shift;
my $port = shift;

	return -1 if(_bind($self->{SOCK_FD}, $port, $self->{PROTO}) < 0);
	$self->{PORT} = $port;

	return 0;
}


sub listen {
my $self = shift;
my $backlog = shift;

	return -1 if(_listen($self->{SOCK_FD}, $backlog) < 0);

	return 0;
}


sub accept {
my $self = shift;

	my ($client, $addr) = _accept($self->{SOCK_FD}, $self->{PROTO});
	return if($client < 0);

	return(Net::Bluetooth->newsocket($self->{PROTO}, $client, $addr));
}


sub close {
my $self = shift;

	_close($self->{SOCK_FD});
	$self->{SOCK_FD} = -1;
}


sub getpeername {
my $self = shift;

	my ($addr, $port) = _getpeername($self->{SOCK_FD}, $self->{PROTO});

	return($addr, $port);
}


sub perlfh {
my $self = shift;

	*SOCK = _perlfh($self->{SOCK_FD});
	return *SOCK;
}


sub fileno {
my $self = shift;

	return($self->{SOCK_FD});
}


#### register a service
sub newservice {
my $class = shift;
my $server_obj = shift;
my $service_id = shift;
my $name = shift;
my $desc = shift;
my $self = {};
my $result = 0;

	
	return unless(exists($server_obj->{PORT}));

	$self->{PROTO} = $server_obj->{PROTO};
	$self->{SERVER_FD} = $server_obj->{SOCK_FD};
	$self->{PORT} = $server_obj->{PORT};
	$self->{SERVICE_ID} = $service_id;
	$self->{SERVICE_NAME} = $name;
	$self->{SERVICE_DESC} = $desc;

	#### On a system where we use service handles
	if(_use_service_handle()) {
		 $result = _register_service_handle($self->{PROTO}, $self->{PORT}, $service_id, $name, $desc);
		 $self->{SERVICE_HANDLE} = $result;
	}

	else {
		$result = _register_service($self->{SERVER_FD}, $self->{PROTO}, $self->{PORT},
		                            $service_id, $name, $desc, 1);
	}


	#### 0 on error, return undef
	return if($result == 0);


	bless($self, $class);
	return $self;
}
 


sub stopservice {
my $self = shift;

	if(_use_service_handle()) {
		_stop_service_handle($self->{SERVICE_HANDLE});
	}

	else {
		_register_service($self->{SERVER_FD}, $self->{PROTO}, $self->{PORT}, $self->{SERVICE_ID},
		                  $self->{SERVICE_NAME}, $self->{SERVICE_DESC}, 0);
	}
}                



1;
__END__

=head1 NAME

Net::Bluetooth - Perl Bluetooth Interface

=head1 SYNOPSIS


  use Net::Bluetooth;

  #### list all remote devices in the area
  my $device_ref = get_remote_devices();
  foreach $addr (keys %$device_ref) {
	print "Address: $addr Name: $device_ref->{$addr}\n";
  }


  #### search for a specific service (0x1101) on a remote device 
  my @sdp_array = sdp_search($addr, "1101", "");

  #### foreach service record
  foreach $rec_ref (@sdp_array) {
	#### Print all available information for service
	foreach $attr (keys %$rec_ref) {
		print "Attribute: $attr Value: $rec_ref->{$attr}\n";
	}
  }


  #### Create a RFCOMM client 
  $obj = Net::Bluetooth->newsocket("RFCOMM");
  die "socket error $!\n" unless(defined($obj)); 
  if($obj->connect($addr, $port) != 0) {
	die "connect error: $!\n";
  }

  #### create a Perl filehandle for reading and writing
  *SERVER = $obj->perlfh();
  $amount = read(SERVER, $buf, 256);
  close(SERVER);



  #### create a RFCOMM server
  $obj = Net::Bluetooth->newsocket("RFCOMM");
  #### bind to port 1
  if($obj->bind(1) != 0) {
	die "bind error: $!\n";
  }

  #### listen with a backlog of 2
  if($obj->listen(2) != 0) {
	die "listen error: $!\n";
  }

  #### register a service
  #### $obj must be a open and bound socket
  my $service_obj = Net::Bluetooth->newservice($obj, "1101", "GPS", "GPS Receiver");
  unless(defined($service_obj)) {
	#### couldn't register service
  }

  #### accept a client connection
  $client_obj = $obj->accept();
  unless(defined($client_obj)) {
	die "client accept failed: $!\n";
  }

  #### get client information
  my ($caddr, $port) = $client_obj->getpeername();

  #### create a Perl filehandle for reading and writing
  *CLIENT = $client_obj->perlfh();
  print CLIENT "stuff";

  #### close client connection
  close(CLIENT);
  #### stop advertising service
  $service_obj->stopservice();
  #### close server connection
  $obj->close();

=head1 DESCRIPTION

This module creates a Bluetooth interface for Perl.

Net::Bluetooth works with the BlueZ libs as well as with
Microsoft Windows.

If you are going to be using a Unix system, the Bluez libs can
be obtained at www.bluez.org. Please make sure these are installed
and working properly before you install the module. Depending on
your system BlueZ maybe already installed, or you may have to build
it yourself and do some configuration. You can verify that BlueZ can
detect devices and services with the utilities that are included with
it (hciconfig, sdptool, hcitool, etc).

If you are using Windows, please make sure you have Service Pack 2
installed and the Microsoft Platform SDK. Also please make sure the
"$win_include" variable at the top of Makfile.PL is set properly. This
needs to point to the SDK include directory for SP2. This is where the
module will look for all the Bluetooth header files (ws2bth.h, etc).

Please check out the samples included in the samples directory for more
general information.

=head1 FUNCTIONS

=over 4

=item get_remote_devices()

Searches for remote Bluetooth devices. The search will
take approximately 5 - 10 seconds (This will be a configurable 
value in the future.). When finished, it will return a hash
reference that contains the device address and name. The
address is the key and the name is the value. Name will be
set to "[unknown]" if the name could not be resolved. See the
NOTES section of this document for more information about this.

=item sdp_search($addr, $uuid, $name) 

This searches a specific device for service records. The first
argument is the device address which is not optional. The uuid
argument can be a valid uuid or "0". The name argument can be a
valid service name or "". It will return services that match
the uuid or service name if supplied, otherwise it will return
all public service records for the device.

The return value is a list which contains a hash reference for
each service record found. The key/values for the hash are as follows:

C<SERVICE_NAME>: Service Name

C<SERVICE_DESC>: Service Description

C<SERVICE_PROV>: Service Provider

C<RFCOMM>: RFCOMM Port

C<L2CAP>: L2CAP Port

C<UNKNOWN>: Unknown Protocol  Port

If any of the values are unavailable, the keys will not exist.

If $addr is "localhost" the call will use the local SDP server.

=back 

=head1 SOCKET OBJECT

The bluetooth socket object is used to create bluetooth sockets and
interface with them. There are two types of sockets supported, RFCOMM and
L2CAP. The methods are listed below.

=over 4

=item newsocket("RFCOMM")

This constructs a socket object for a RFCOMM socket or L2CAP
socket.

=item connect($addr, $port)

This calls the connect() system call with the address and port you
supply. You can use this to connect to a server. Returns 0 on
success.

=item bind($port)

This calls the bind() system call with the port you provide. 
You can use this to bind to a port if you are creating a server.
Returns 0 on success. As a side note, RFCOMM ports can only range
from 1 - 31.

=item listen($backlog)

This calls the listen() system call with the backlog you provide.
Returns 0 on success.

=item accept()

This calls the accept() system call and creates a new bluetooth
socket object which is returned. On failure it will return undef.

=item perlfh()

This call returns a Perl filehandle for a open socket. You can
use the Perl filehandle as you would any other filehandle, except
with Perl functions that use the socket address structure. This 
provides a easy way to do socket IO instead of doing it through the
socket object. Currently this is the only way to do socket IO,
although soon I will provide read/write calls through the object
interface.

=item close()

This closes the socket object. This can also be done through the
Perl close() call on a created Perl filehandle.

=item getpeername()

This returns the address and name for a open bluetooth socket. (BlueZ only
for now)

=back

=head1 SERVICE OBJECT

The service object allows you to register a service with your local
SDP server. The methods are as follows:

=over 4

=item newservice($obj, $service_uuid, $service_name, $service_desc)

This registers a service with your local SDP server. The first
argument is a open and bound socket that you created with newsocket().
The second argument is the service uuid. The third argument is the
service name. The fourth argument is the service description.

The return value is a new service object. This will be undefined
if there was an error.

=item stop_service()

This unregisters your service with the local SDP server. The service 
will be unregistered without this call when the application exits.

=back

=head1 NOTES

All uuids used with this module can either be 128 bit values:
"00000000-0000-0000-0000-000000000000" or 16 bit values: "0000". All values
must be represented as strings (enclosed in quotes), and must be hexadecimal
values.

Windows will not immediately return the device name if it is not already
cached. Also there is no mechinism to alert the system when it has acquired
the device name. Therefore you may have to call get_remote_devices() twice
before the name shows up. I'll see if this can be handled better in the
future.

Currently on Windows the service name and description returned by sdp_search()
are not setting their terminating NULL character properly. This can result in
some garbage characters at the end of the string. I am looking at parsing
the raw record to fix this problem.

=head1 REQUIREMENTS

You need BlueZ or Microsoft Service Pack 2 installed and the Microsoft Platform SDK.
Windows needs at least Perl 5.8.

=head1 AUTHOR

Ian Guthrie
IGuthrie@aol.com

Copyright (c) 2006 Ian Guthrie. All rights reserved.
               This program is free software; you can redistribute it and/or
               modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
