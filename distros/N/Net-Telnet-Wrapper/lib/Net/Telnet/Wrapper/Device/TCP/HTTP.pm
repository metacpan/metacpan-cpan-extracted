package Net::Telnet::Wrapper::Device::TCP::HTTP;

## ----------------------------------------------------------------------------------------------
## Net::Telnet::Wrapper::Device::TCP::HTTP
##
## Device class for connecting to TCP HTTP port
##
## $Id: HTTP.pm 39 2007-07-11 14:29:01Z mwallraf $
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

	my  $self = $class->SUPER::new(%parm, 'Telnetmode' => 0, 'port' => 80);	
	bless($self,$class);

	*$self->{'net_telnet_wrapper'}->{'device_class'} = "TCP::HTTP";
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


sub test_url()  {
	my ($self, $url) = @_;
	return $self->SUPER::cmd("GET $url HTTP/1.0\n\n");
}


1;



__END__

=head1 NAME

Net::Telnet::Wrapper::Device::TCP::HTTP

=head1 DESCRIPTION

TCP::HTTP device class template.

This device class can be used to connect to HTTP servers over port 80

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

=head1 SPECIFICS

    - Net::Telnet is called with Telnetmode disabled
    - Some custom procedures are defined

=head1 AUTHOR

Maarten Wallraf E<lt>perl@2nms.comE<gt>

=cut
