package Net::Telnet::Wrapper::Device::Template::New;

## ----------------------------------------------------------------------------------------------
## Net::Telnet::Wrapper::Device::Template::New
##
## Template for creating new device class templates
##
## $Id$
## $Author: mwallraf $
## $Date: 2007-07-11 16:29:01 +0200 (Wed, 11 Jul 2007) $
##
## This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself.
## ----------------------------------------------------------------------------------------------

$VERSION = "0.1";

use Net::Telnet::Wrapper::Device;
use strict;
use warnings;

use vars qw( @ISA );

@ISA = ("Net::Telnet::Wrapper::Device");

sub new()  {
	my ($this, %parm) = @_;
	my  $class = ref($this) || $this;



	## ------------------------------------------------------------------------------------------
	## create a new Net::Telnet::Wrapper::Device object which actually calls
	## Net::Telnet::new() or Net::Telnet::Cisco::new()
	## Specify additional Net::Telnet parameters if needed like "Port" => 80 or "Telnetmode" => 0
	## ------------------------------------------------------------------------------------------
	my  $self = $class->SUPER::new(%parm);	
	bless($self,$class);




	## ----------------------------------------
	## define the template specific parameters
	## ----------------------------------------

	## the name of this device class
	*$self->{'net_telnet_wrapper'}->{'device_class'} = "Template::New";
	
	## does this device supports login mode
	*$self->{'net_telnet_wrapper'}->{'mode_support_login'} = 0;
	
	## does this device supports enable mode
	*$self->{'net_telnet_wrapper'}->{'mode_support_enable'} = 0;	
	
	## does this device supports config mode
	*$self->{'net_telnet_wrapper'}->{'mode_support_config'} = 0;
	
	## when we see this prompt we are connected to the device
	## *** *ONLY* THE SESSION PROMPT HAS LEADING AND TRAILING SLASHES FOR THE REGEX ***
	*$self->{'net_telnet_wrapper'}->{'session_prompt'} = '/[\$%#>] $/';
	
	## when we see this prompt we are in login mode
	*$self->{'net_telnet_wrapper'}->{'prompt_login'} = '[\$%#>] $';	

	## when we see this prompt we are in enable mode
	*$self->{'net_telnet_wrapper'}->{'prompt_enable'} = '(enable)';	

	## when we see this prompt we are in config mode
	*$self->{'net_telnet_wrapper'}->{'prompt_config'} = '<config>';	

	## this is the command used to disable terminal paging, leave blank if not supported
	*$self->{'net_telnet_wrapper'}->{'terminal_length_cmd'} = 'terminal length 0';	

	## this is the command used to go to config mode, leave blank if not supported
	*$self->{'net_telnet_wrapper'}->{'config_command'} = 'config terminal';

	## if enabled then we want to run the _post_login commands after logging in
	## override the _post_login procedure if you want to change its behaviour
	*$self->{'net_telnet_wrapper'}->{'run_post_login'} = 1,	

	## if enabled then we want to run the _post_login commands after logging in
	## override the _post_login procedure if you want to change its behaviour
	*$self->{'net_telnet_wrapper'}->{'run_post_enable'} = 0,


	$self->open();

	$self->_init();
	return($self);
}

## here you can execute additional commands that will run right after opening the TCP socket
sub _init()  {
	my ($self) = shift;
}





## ---------------------------------------------------------------------------------------------
## Override the default methods of Net::Telnet or Net::Telnet::Cisco
## If you do not need to override any of these methods then don't include them in your template
## Below are some examples of methods that are already overrided in Net::Telnet::Wrapper::Device
## ---------------------------------------------------------------------------------------------


## close method : calls the default Net::Telnet::close method but first tries to exit gently
##                from the session by sending the correct logoff commands
##                This avoids that TCP sockets remain in the netstat table. 
##                Specially useful when connecting to hundreds of device in a short period.
## optional parameters are config =>  (command used to exit from 'config' mode)
##                         enable =>  (command used to exit from 'enable' mode)
##                         login =>   (command used to exit fom 'login' mode)
sub close()  {
	my ($self) = shift;
	$self->SUPER::close( 'config' => "quit", 'login' => "exit", 'enable' => 'exit');
}


## login method : use your own login method if the device is not supported by the default prompts
##                of Net::Telnet or Net::Telnet::Cisco
##
sub login()  {
	my $self = shift;
	
	## define your own sequence of readline and waitfor methods here
	## see Packeteer::PacketShaper for an example
	
	## if needed call the default Net::Telnet::login procedure after you have run your own
	## commands
	$self->SUPER::login(@_);
}

## _post_login : by default this procedure is called right after logging in
##               Default is to run the command to disable terminal paging
##               Override this to run your own commands
sub _post_login()  {
	my $self = shift;
	
	## define your own commands here
	
	## if needed call the default Net::Telnet::Wrapper::Device::_post_login procedure after you have run your own
	## commands
	$self->SUPER::_post_login(@_);
}

## enable method : use your own enable method if the device is not supported by the default prompts
##                of Net::Telnet::Cisco
##
sub enable()  {
	my $self = shift;
	
	## define your own sequence of readline and waitfor methods here
	## see Packeteer::PacketShaper for an example
	
	## if needed call the default Net::Telnet::Cisco::enable procedure after you have run your own
	## commands
	$self->SUPER::enable(@_);
}

## _post_enable : by default this procedure is called right after going to enable mode
##               Default is to run the command to disable terminal paging
##               Override this to run your own commands
sub _post_enable()  {
	my $self = shift;
	
	## define your own commands here
	
	## if needed call the default Net::Telnet::Wrapper::Device::_post_login procedure after you have run your own
	## commands
	$self->SUPER::_post_enable(@_);
}


## config method : use your own config method 
##
sub config()  {
	my $self = shift;
	
	## define your own sequence of readline and waitfor methods here
	
	## if needed call the default Net::Telnet::Wrapper::Device::config procedure after you have run your own
	## commands
	$self->SUPER::config(@_);
}








## ---------------------------------------------------------------------------------------------
## Define your own custom procedures for this device type if needed. For example if there is
## a specific sequence of commands you always need then you can add the procedure for this here.
## Obviously these procedures are ONLY known for this device type. Other device types do not 
## have these custom procedures defined.
##
## ! NOTE !
## 
## The output of ALL procedures is added to the Output array which can be called by 
##   $wrapper->GetOutput()
## So if you don't want this to happen then make sure you return an empty value
##
## Procedure names starting with get_ are NOT being added to the Output array.
##
## ---------------------------------------------------------------------------------------------


## This procedure will run "uname -a" and return the output
## The name starts with get_ so the output will not saved in the Output array and will
## therefore not be seen when calling $wrapper->GetOutput()
sub get_hostname()  {
	my $self = shift;
	
	return $self::SUPER->cmd("uname -a");
}


## The same procedure but does not start with get_ so the output is automatically saved in 
## the output array.
## Running $wrapper->GetOutput() will include the output of this command
sub find_hostname()  {
	my $self = shift;
	
	return $self::SUPER->cmd("uname -a");
}



1;



__END__

=head1 NAME

Net::Telnet::Wrapper::Device::Template::New

=head1 DESCRIPTION

Template::New device class template.

Use this file as a template for creating new Device Class modules.

Check the contents of the source to have detailed information about each parameter.

Do not call this module directly.

=head1 AUTHOR

Maarten Wallraf E<lt>perl@2nms.comE<gt>

=cut
