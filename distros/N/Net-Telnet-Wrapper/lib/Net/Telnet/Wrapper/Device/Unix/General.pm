package Net::Telnet::Wrapper::Device::Unix::General;

## ----------------------------------------------------------------------------------------------
## Net::Telnet::Wrapper::Device::Unix::General
##
## Device class for Cisco routers and switches based on IOS
##
## $Id: General.pm 39 2007-07-11 14:29:01Z mwallraf $
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

	*$self->{'net_telnet_wrapper'}->{'device_class'} = "Unix::General";
	*$self->{'net_telnet_wrapper'}->{'mode_support_enable'} = 0;	# router supports enable mode
	*$self->{'net_telnet_wrapper'}->{'mode_support_config'} = 0;	# router supports config mode
#	*$self->{'net_telnet_wrapper'}->{'session_prompt'} = '/[\$%#>] $/';		# when we see this we're in login mode
#	*$self->{'net_telnet_wrapper'}->{'prompt_login'} = '[\$%#>] $';		# when we see this we're in login mode
	*$self->{'net_telnet_wrapper'}->{'prompt_enable'} = '';	# when we see this we're in enable mode
	*$self->{'net_telnet_wrapper'}->{'prompt_config'} = '';	# when we see this we're in config mode
	*$self->{'net_telnet_wrapper'}->{'terminal_length_cmd'} = '';	# if set then the terminal length will be set to 0 before each command
	*$self->{'net_telnet_wrapper'}->{'config_command'} = '';	# command used to go to config mode

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
	$self->SUPER::close( "login" => "exit");
}

1;



__END__

=head1 NAME

Net::Telnet::Wrapper::Device::Unix::General

=head1 DESCRIPTION

Unix::General device class template.

This device class can be used to connect any Unix server with default prompts.
This is the same when using Net::Telnet with default parameters.

Do not call this module directly.

=head1 DEVICE CLASS SPECIFIC PROCEDURES

Following device class specific procedures are defined.  All commands can also be executed using
the default cmd() command which is inherited from Net::Telnet.

=over 4

=item test_url url

This procedure connects to an HTTP server on port 80 and tries to get an url.
To avoid hanging sessions etc. a GET is done with HTTP version 1.0

Return value is everything that HTTP GET returns

=back

=head1 SUPPORTED MODES

    CONNECT
    LOGIN

=head1 SPECIFICS

    - close method overrides default method

=head1 AUTHOR

Maarten Wallraf E<lt>perl@2nms.comE<gt>

=cut
