package Net::Telnet::Wrapper;

## ----------------------------------------------------------------------------------------------
## Net::Telnet::Wrapper
##
## A wrapper or extension for Net::Telnet and Net::Telnet::Cisco which implements
## some default procedures like multiple login attempts, output formatting, error checking etc.
## By default this supports many devices like Cisco routers, switches, firewalls but
## also Nortel, Packeteer, Unix etc.  
## Basically it's possible to add support for almost any applicationt that listens on a TCP port.
##
## Net::Telnet::Wrapper is not a replacement for Net::Telnet(::Cisco) so ALL
## the original functions and parameters can still be used.
##
## $Id: Wrapper.pm 39 2007-07-11 14:29:01Z mwallraf $
## $Author: mwallraf $
## $Date: 2007-07-11 16:29:01 +0200 (Wed, 11 Jul 2007) $
##
## This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself.
## ----------------------------------------------------------------------------------------------

$VERSION = "0.1";

use strict;
use warnings;
use Carp;
use Data::Dumper;
require 5.002;

use vars qw( $AUTOLOAD $DEBUG );

$Carp::Verbose = 1;
$Carp::CarpLevel = 1;
$DEBUG = 1;


BEGIN { $SIG{'__WARN__'} = sub { carp($_[0]) if ($DEBUG); } }


sub new()  {
	my ($this, %parm) = @_;
	my  $class = ref($this) || $this;
	my  $self = {};	
	
	$self->{'telnet_session'} = undef;			# contains reference to telnet sessions

	$self->{'identifier'} = &_generate_id();	# unique identifier for each session, do I really need this ??
	
	$self->{'error_occurred'} = 0;	# true if the last command generated an error
	$self->{'error_last'} = "";		# displays the last error
	
	$self->{'output'} = [];			# output of all commands

	bless($self, $class);
	$self->_initialize(%parm);
	return($self);
}


sub _initialize()  {
	my ($self,%parm) = @_;
	my $deviceclass;
	$self->_clear_error();
	# we don't want to pass device_clas to Net::Telnet or Net::Telnet::Cisco
	# TODO: find a better way to do this
	if (defined($parm{'device_class'}))  {
		$deviceclass = $parm{'device_class'};
		delete $parm{'device_class'};
	} else {  
		$deviceclass = "Unix::General";
	}
	if (&_is_installed("Net::Telnet::Wrapper::Device::$deviceclass"))  {
		$self->{'telnet_session'} = "Net::Telnet::Wrapper::Device::$deviceclass"->new(%parm);
	}
	else {
		$self->_set_error("ERROR: Unable to create new object, failed to load device_class libraries");
	}
}


sub get_id()  {
	my ($self) = @_;
	return $self->{'identifier'};
}


sub AUTOLOAD()  {
	my ($self,@args) = @_;
	my $cmd = $Net::Telnet::Wrapper::AUTOLOAD;
	my @rc;
	$cmd =~ s/.*:://;
	$self->_clear_error();
	unless ($self->{'telnet_session'})  {
		$self->_set_error("ERROR: No telnet session defined or command '$cmd' does not exist");
		&croak($self->_get_error());
	}
	eval {
		if ($self->{'telnet_session'})  {
			@rc = $self->{'telnet_session'}->$cmd(@args);
		}
	};
	if ($@)  {
		$self->_set_error($@);
		&croak($self->_get_error());
	}
	else  {
		# do not save the output if it's a "get_" command
		$self->_clear_error();
		push (@{$self->{'output'}}, @rc) unless ($cmd =~ /^get/);
		return @rc;
	}
}


sub DESTROY()  {
	my ($self) = @_;
	if ($self->{'telnet_session'})  {
		$self->_quit();
	}
}



sub _is_installed {
	my($module) = @_;
	my $rc;
	(my $filename = $module) =~ s@::@/@g;
	$rc = eval { require "$filename.pm" };
	if ($@)  {
		&croak("ERROR: device_class '$module' cannot be found");
	}
	return $rc;
}

sub _set_error()  {
	my ($self, $error_message) = @_;
	$self->{'error_occurred'} = 1;
	$self->{'error_last'} = $error_message;
}

sub _clear_error()  {
	my ($self) = @_;
	$self->{'error_occurred'} = 0;
	$self->{'error_last'} = "";
}

sub _get_error()  {
	my ($self) = @_;
	return $self->{'error_last'};
}

sub _generate_id()  {
	my $session_id  ="";
	my $length=16;
	my ($i, $j);

	for($i=0 ; $i< $length ; )	{
		$j = chr(int(rand(127)));
		if($j =~ /[a-zA-Z0-9]/)	{
			$session_id .=$j;
			$i++;
		}
	}
	
	return $session_id;
}

# exit connection from remote connection,
#  if not then the socket is closed from client side and connection is kept in tcp TIME_WAIT state
sub _quit()  {
	my ($self) = shift;
	eval {
		if ($self->{'telnet_session'})  {
#			$self->close();
			undef $self->{'telnet_session'};
		}
		# allow the session to close down gently
		sleep(1);
		if (defined($self->{'telnet_session'}))  {
			undef $self->{'telnet_session'};
		}
	};
}

sub GetLastError()  {
	my ($self) = shift;
	return $self->_get_error();
}

sub IsSuccess()  {
	my ($self) = shift;
	return !$self->{'error_occurred'};
}

sub GetOutput()  {
	my ($self) = shift;
	return $self->{'output'};
}

sub Quit()  {
	my $self = shift;
	$self->_quit();
}


### TODO: WE NEED THIS FOR MULTITHREADING ????
sub CLONE_SKIP { 1 }




1;

__END__

=head1 NAME

Net::Telnet::Wrapper - wrapper or extension for Net::Telnet and Net::Telnet::Cisco

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use Net::Telnet::Wrapper;

    ## connect to Cisco router and execute show version + show clock
    my $w = Net::Telnet::Wrapper->new('device_class' => 'Cisco::IOS', -host => 'routerA');
    eval {
    	$w->login( 'name' => "mwallraf", 'passwd' => "<mypass>", 'Passcode' => "<mypass>");
    	$w->enable( 'name' => "mwallraf", 'passwd' => "<mypass>", 'Passcode' => "<mypass>");
    	$w->cmd('show version');
    	$w->cmd('show clock');
    };
    die $@ if ($@);
    print join("\n", @{$w->GetOutput()} );


    ## check if we're logged in to the router in enable mode
    print "We are connected to the router in ", $w->get_mode(), " mode\n";
    

    ## check if www.google.com is working
    my $w = Net::Telnet::Wrapper->new('device_class' => 'TCP::HTTP', -host => 'www.google.com');
    eval {
    #	print $w->cmd("GET /index.html HTTP/1.0\n\n");
    #	or
    	print $w->test_url("/index.html");
    };
    die $@ if ($@);


=head1 DESCRIPTION

A wrapper or extension for L<Net::Telnet> and L<Net::Telnet::Cisco> that adds some
default procedures like multiple login attempts as well as output formatting, error checking etc.

The wrapper has templates or device classes defined for many devices like Cisco routers, switches, 
firewalls but also Nortel, Packeteer, Unix etc.  
It's possible to add templates for almost any application that listens on a TCP port.
All templates can be found in the Device folder.

Net::Telnet::Wrapper is not a replacement for Net::Telnet(::Cisco) and has to be used exactly
the same way with the same parameters etc. It does have a few additional parameters and procedures.

=head1 WHY USING Net::Telnet::Wrapper

I am already using Net::Telnet, why should I use Net::Telnet::Wrapper?  

	You can use the exact same code no matter to which kind of device you are connecting to.

	No need to write any code anymore for trying to reconnect in case the first connection attempt fails.

	It is possible to get all the output at once, even if you have executed many commands.

	Create your own device templates and override the default L<Net::Telnet> procedures if needed.

	If you are connecting to network devices you want to know if you are connected in login mode, enable mode
	or config mode. This module keeps track of this and you can always ask for the current mode.

=head1 PROCEDURES

All L<Net::Telnet> and L<Net::Telnet::Cisco> procedures can be used as described in their own manpages. 
The following procedure are specific for this module.

=over 4

=item new - create a new Net::Telnet::Wrapper object

This is the constructor. This inherits from Net::Telnet::new() and uses the same parameters in addition to
the following parameters :

$obj = new Net::Telnet::Wrapper ( 'device_class' => '$Device::Type', '-device' => $device );

    $obj = new Net::Telnet::Wrapper (
                                       '-device'       => '$host',
                                       ['device_class' => '$Device::Type',]
                                       ['retry_open'   => '3',]
                                       ['retry_login'  => '3',]
                                       ['retry_cmd'    => '3',]
                                       ['inherit_auto' => '1',]
                                       ['inherit_class' => 'Net::Telnet',]
                                    );


    device_class = specify the device type, default = Unix::General
                   see SUPPORTED DEVICES for all default device class templates
                   
    -device = the device to connect to, THIS IS THE ONLY DIFFERENCE COMPARED TO NET::TELNET !
    
    retry_open = how many times do you want to re-attempt to connect to a device if it fails
    
    retry_login = how many times do you want to re-attempt to login to a device
    
    retry_cmd = how many times to you want to re-attempt to execute a command
    
    inherit_auto = By default all device class templates starting with 'Cisco' will inherit
                   from Net::Telnet::Cisco.  All others will inherit from Net::Telnet.
                   Disable this switch if you want to override this and specify your own
                   inheritance.
                   
    inherit_class = In case you disable inherit_auto then specify your own inheritance class.
    

=item get_device_class

Displays which device class we are using.
    
ex. print "device class = '",$w->get_device_class(),"\n";
    
This can show "Cisco::IOS" or "Unix::General" for example.

=item get_id

Every telnet session has its own unique id. This will show you the id.

=item get_mode

Returns the mode we are currently in. If are logged in then this will return LOGIN.
See CONNECTION MODES for more info.

=item GetLastError

In case a problem occurred then this will show you the last error message.

=item GetOutput

This returns a reference to an array.

The array contains the output of each executed command. 

ex. 	$w->cmd('show version');
	$w->cmd('show clock');
	print join("\n", @{$w->GetOutput()} );
	
The above will fill the output array with two elements. One element for each command.	

=item IsSuccess

Returns true if the last function did not generate an error. Returns false otherwise, the error can then
be retrieved with GetLastError()

=item login

This logs in to the device. It calls the default Net::Telnet::login procedure but catches any errors and 
re-attempts the login process in case of failure.

After logging in the _post_login commands are executed an by default this means that terminal paging is
disabled if the device supports it. The terminal paging command is defined in the device class template files.
Override the _post_login procedure in the template to change its behaviour.

=item enable

This enters the enable mode if the device supports it. 
It calls the default Net::Telnet::Cisco::enable procedure but catches any errors and re-attempts the 
enable process in case of failure.

After going to enable mode the _post_enable commands are executed an by default there are no post-enable commands
defined. 
Override the _post_enable procedure in the template to change its behaviour.

=item config

This enters the config mode if the device supports it. 
It calls the default Net::Telnet::cmd procedure and executes the command needed to go to config mode. 
This command is defined in each device template.
If needed it re-attempts to execute the command in case of failure.

=item Quit

Same as Net::Telnet::close()

Closes the telnet connection gently, meaning that if possible a logoff command is sent rather then just
cutting of the TCP session.

=back

=head1 CONNECTION MODES

Net::Telnet::Wrapper keeps track of the current connection mode you are in. There are 4 modes pre-defined
but not all device types will support all of them.

This is mainly useful when connecting to network devices because usually you want to know if you have
privileged or configuration commands enabled.

=over 4

=item CONNECT

This is the mode you are in when you open a TCP port. For example when you do "telnet device" without 
logging in then you are in CONNECT mode. Connecting to a HTTP port for example will be in CONNECT mode as well.

=item LOGIN

After logging in to a device you are in LOGIN mode. This is the case for Unix servers, network devices etc.

=item ENABLE

Some network devices differentiate between privileged and non-privileged command sets. When you have access
to privileged commands you will be in ENABLE mode. For Cisco this means entering the command "enable", for 
PacketShapers the command "touch" etc.

=item CONFIG

This is the mode when you are able to make configuration changes. For Cisco devices this means 
entering "config terminal".

=back

=head1 SUPPORTED DEVICES - DEVICE CLASS

Templates -or device classes- for the supported devices can be found in the Devices folder. 
ex. For Cisco routers there is a module called Net::Telnet::Wrapper::Device::Cisco::IOS.

A template contains the default prompts for a device and specific logon or logoff commands etc.

Use the template name (ex. Cisco::IOS) as parameter when creating a new Net::Telnet::Wrapper object.

The following templates or device classes are known at this moment :

=over 4

=item Cisco::IOS

Cisco devices based on IOS software.

=item Cisco::CATOS

Cisco switches based on CATOS

=item Cisco::ACNS

Cisco Cache Engines or Cisco Content Modules.  All devices based on ACNS software.

=item Cisco::ASA

Cisco ASA firewalls.

=item Nortel::Contivity

Nortel Contivity switches, VPN concentrators.

=item Packeteer::PacketShaper

PacketShapers from Packeteer

=item TCP::HTTP

Connect to the HTTP port 80. Some additional procedures are defined in this template.

=item TCP::POP

Connect to the POP3 port 110. Default procedures are defined for logging in etc.

=item Unix::General

Connect to any general unix device. When using this template it is exactly the same as using Net::Telnet with
default parameters.

=back

=head2 ADDING DEVICES

New templates can be added. Just use the existing ones as example or start from the device class Template::New.

Basically it all comes down to defining the login modes (connect, login, enable, config) and the corresponding
prompts.

If needed the default Net::Telnet procedures can be overriden in the templates, for example to define your custom
login or logout procedure.

If you have created your own templates just let me know and I will add them to the distribution.

=head1 EXAMPLES

Check the test directory in the distribution for more examples or check http://www.2nms.com

=over 4

=item Cisco router example

	#!/usr/bin/perl

	use strict;
	use warnings;

	use Net::Telnet::Wrapper;
	use Data::Dumper;

	my $w = Net::Telnet::Wrapper->new('device_class' => 'Cisco::IOS', -host => '10.131.128.1' );

	eval {
		print "mode = ",$w->get_mode(),"\n";

		$w->login( 'name' => "mwallraf", 'passwd' => "<mypass>", 'Passcode' => "<mypass>");
		$w->enable( 'name' => "mwallraf", 'passwd' => "<mypass>", 'Passcode' => "<mypass>");

		$w->cmd('show version');

		print "mode = ",$w->get_mode(),"\n";
	};
	if ($@)  {
		die $@;
	}

	print @{$w->GetOutput()};

	print "device class = '",$w->get_device_class(),"\n";
	print "id = ",$w->get_id(),"\n";
	print "test = ",$w->test(),"\n";

=item UNIX example

	#!/usr/bin/perl

	use strict;
	use warnings;

	use Net::Telnet::Wrapper;
	use Data::Dumper;

	my $w = Net::Telnet::Wrapper->new('device_class' => 'Unix::General', -host => 'linux1');

	eval {
		print "MODE = ",$w->get_mode(),"\n";

		$w->login( 'name' => "mwallraf", 'passwd' => "<mypass>");

		$w->cmd('uname -a');

		print "MODE = ",$w->get_mode(),"\n";
	};
	if ($@)  {
		die $@;
	}

	print @{$w->GetOutput()};

	print "device class = '",$w->get_device_class(),"\n";
	print "id = ",$w->get_id(),"\n";
	print "test = ",$w->test(),"\n";

=item HTTP example

	#!/usr/bin/perl

	use strict;
	use warnings;

	use Net::Telnet::Wrapper;
	use Data::Dumper;

	my $w = Net::Telnet::Wrapper->new('device_class' => 'TCP::HTTP', -host => 'www.google.com' );

	eval {
		print "MODE = ",$w->get_mode(),"\n";

	#	$w->cmd("GET /index.html HTTP/1.0\n\n");
	#	or
		$w->test_url("/index.html");

		print "MODE = ",$w->get_mode(),"\n";
	};
	if ($@)  {
		die $@;
	}

	print @{$w->GetOutput()};

	print "device class = '",$w->get_device_class(),"\n";
	print "id = ",$w->get_id(),"\n";
	print "test = ",$w->test(),"\n";

=item POP3 example

	#!/usr/bin/perl

	use strict;
	use warnings;

	use Net::Telnet::Wrapper;
	use Data::Dumper;

	my $w = Net::Telnet::Wrapper->new('device_class' => 'TCP::POP', -host => '<my mail server>' );

	eval {
		print "MODE = ",$w->get_mode(),"\n";

		$w->pop_login("mwallraf", "<mypass>");
		my @count = $w->get_count_messages();
		print "There are $count[0] messages on the server\n";

		print "MODE = ",$w->get_mode(),"\n";
	};
	if ($@)  {
		die $@;
	}

	print @{$w->GetOutput()};

	print "device class = '",$w->get_device_class(),"\n";
	print "id = ",$w->get_id(),"\n";
	print "test = ",$w->test(),"\n";

=back

=head1 TODO

    - add additional device class templates
    - improve debug logging
    
=head1 CAVEATS

This is an extension to the existing L<Net::Telnet> modules, all procedures are inherited so in case of 
problems check the forums for these modules first. Also do not forget to check the debugging part in the
Net::Telnet doc.

Net::Telnet::Wrapper can be used in exactly the same way as the existing Net::Telnet modules, the major
difference is that the prompts for many devices are pre-configured in separate device modules. 

=head1 AUTHOR

Maarten Wallraf E<lt>perl@2nms.comE<gt>

=cut
