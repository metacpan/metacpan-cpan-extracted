package Net::Telnet::Wrapper::Device::Cisco::ASA;

## ----------------------------------------------------------------------------------------------
## Net::Telnet::Wrapper::Device::Cisco::ASA
##
## Device class for Cisco ASA firewalls
##
## $Id: ASA.pm 39 2007-07-11 14:29:01Z mwallraf $
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

	my  $self = $class->SUPER::new(%parm);	
	bless($self,$class);

	*$self->{'net_telnet_wrapper'}->{'device_class'} = "Cisco::ASA";
	*$self->{'net_telnet_wrapper'}->{'mode_support_enable'} = 1;	# router supports enable mode
	*$self->{'net_telnet_wrapper'}->{'mode_support_config'} = 1;	# router supports config mode
	*$self->{'net_telnet_wrapper'}->{'session_prompt'} = '/(?m:^[\r\w.-]+\s?(?:\(config[^\)]*\))?\s?[\$#>]\s?(?:\(enable\))?\s*$)/';		# when we see this we're in login mode
	*$self->{'net_telnet_wrapper'}->{'prompt_login'} = '(?m:^[\r\w.-]+\s?(?:\(config[^\)]*\))?\s?[\$#>]\s?(?:\(enable\))?\s*$)';		# when we see this we're in login mode
	*$self->{'net_telnet_wrapper'}->{'prompt_enable'} = '#';	# when we see this we're in enable mode
	*$self->{'net_telnet_wrapper'}->{'prompt_config'} = 'conf';	# when we see this we're in config mode
	*$self->{'net_telnet_wrapper'}->{'terminal_length_cmd'} = 'terminal pager lines 0';	# if set then the terminal length will be set to 0 before each command
	*$self->{'net_telnet_wrapper'}->{'config_command'} = 'conf t';	# command used to go to config mode
	*$self->{'net_telnet_wrapper'}->{'run_post_login'} = 0,		# run post login commands
	*$self->{'net_telnet_wrapper'}->{'run_post_enable'} = 1,	# run post enable login commands

	$self->open();

	$self->_init();
	return($self);
}

sub _init()  {
	my ($self) = shift;
}

# override the default close method
# parameters are config =>  (command used to exit 'config' mode)
#                enable =>  (command used to exit 'enable' mode)
#                login =>   (command used to exit 'login' mode)
sub close()  {
	my ($self) = shift;
	
	## ASA or PIX remembers the terminal pager setting, so let's restore it to default (if needed)
	if (*$self->{'net_telnet_wrapper'}->{'terminal_length_cmd'} && *$self->{'net_telnet_wrapper'}->{'run_post_enable'})  {
		## this only works in enable mode
		if ($self->SUPER::_mode_enable())  {
			my $org_retries = *$self->{'net_telnet_wrapper'}->{'retry_cmd'};
			*$self->{'net_telnet_wrapper'}->{'retry_cmd'} = 1;
			$self->SUPER::cmd("terminal pager lines 24");
			*$self->{'net_telnet_wrapper'}->{'retry_cmd'} = $org_retries;
		}
	}
	
	$self->SUPER::close( "config" => "exit", "enable" => "exit", "login" => "exit");
}


1;


__END__

=head1 NAME

Net::Telnet::Wrapper::Device::Cisco::ASA

=head1 DESCRIPTION

Cisco::ASA device class template.

This defines the default prompts for this device type.

Do not call this module directly.

=head1 SUPPORTED MODES

    CONNECT
    LOGIN
    ENABLE
    CONFIG

=head1 SPECIFICS

    - After logging in go to enable mode and reset terminal paging    
    - close method overrides default method
    - before disconnecting terminal paging is enabled again
    
=head1 AUTHOR

Maarten Wallraf E<lt>perl@2nms.comE<gt>

=cut
