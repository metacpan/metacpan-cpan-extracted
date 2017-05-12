package Net::Telnet::Wrapper::Device::TCP::General;

## ----------------------------------------------------------------------------------------------
## Net::Telnet::Wrapper::Device::TCP::General
##
## Device class for connecting to any TCP port
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

	my  $self = $class->SUPER::new(%parm, 'Telnetmode' => 0);	
	bless($self,$class);

	*$self->{'net_telnet_wrapper'}->{'device_class'} = "TCP::General";
	*$self->{'net_telnet_wrapper'}->{'mode_support_login'} = 0;	# router supports enable mode
	*$self->{'net_telnet_wrapper'}->{'mode_support_enable'} = 0;	# router supports enable mode
	*$self->{'net_telnet_wrapper'}->{'mode_support_config'} = 0;	# router supports config mode
	*$self->{'net_telnet_wrapper'}->{'terminal_length_cmd'} = '';	# if set then the terminal length will be set to 0 before each command

	$self->open();

	$self->_init();
	return($self);
}

sub _init()  {
	my ($self) = shift;
}


1;



__END__

=head1 NAME

Net::Telnet::Wrapper::Device::TCP::General

=head1 DESCRIPTION

TCP::General device class template.

This device class can be used to connect to any TCP port

Do not call this module directly.

=head1 SUPPORTED MODES

    CONNECT

=head1 SPECIFICS

    - Net::Telnet is called with Telnetmode disabled

=head1 AUTHOR

Maarten Wallraf E<lt>perl@2nms.comE<gt>

=cut
