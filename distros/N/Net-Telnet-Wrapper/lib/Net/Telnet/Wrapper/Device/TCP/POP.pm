package Net::Telnet::Wrapper::Device::TCP::POP;

## ----------------------------------------------------------------------------------------------
## Net::Telnet::Wrapper::Device::TCP::POP
##
## Device class for connecting to TCP POP3 port
##
## $Id: POP.pm 39 2007-07-11 14:29:01Z mwallraf $
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

	my  $self = $class->SUPER::new(%parm, 'Telnetmode' => 0, 'Port' => 110);	
	bless($self,$class);

	*$self->{'net_telnet_wrapper'}->{'device_class'} = "TCP::POP";
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



## this is from the Net::Telnet doc
sub pop_login()  {
	my ($self, $user, $pass) = @_;

	## Read connection message.
	my $line = $self->SUPER::getline();
	croak ("UNEXPECTED PROMPT : $line") unless ($line =~ /^\+OK/);

	## Send user name.
	$self->SUPER::print("user $user");
	$line = $self->SUPER::getline();
	croak ("UNEXPECTED PROMPT : $line") unless ($line =~ /^\+OK/);

	## Send password.
	$self->SUPER::print("pass $pass");
	$line = $self->SUPER::getline();
	croak ("UNEXPECTED PROMPT : $line") unless ($line =~ /^\+OK/);
	
	return;
}


sub get_count_messages()  {
	my ($self) = @_;

	my @list = $self->SUPER::print("stat");
	my $line = $self->SUPER::getline();
	$line =~ /([0-9]+) [0-9]+$/;
	return $1;
}

sub get_message()  {
	my ($self, $msgid) = @_;
	
	my $msg = $self->SUPER::cmd("TOP $msgid 1");
	my $line = $self->SUPER::getline();
	
	return $msg;
}

sub close()  {
	my ($self) = shift;

	$self->SUPER::close('connect' => 'quit');
}


1;


__END__

=head1 NAME

Net::Telnet::Wrapper::Device::TCP::POP

=head1 DESCRIPTION

TCP::POP device class template.

This device class can be used to connect to POP3 servers and retrieve mails etc. via telnet.

Do not call this module directly.

=head1 DEVICE CLASS SPECIFIC PROCEDURES

Following device class specific procedures are defined.  All commands can also be executed using
the default cmd() command which is inherited from Net::Telnet.

=over 4

=item pop_login user, pass

This procedure logs in to the POP3 server with the given username and password.
Croaks if an error occurred.

=item get_count_messages

This procedure returns the number of messages for the POP3 account. It assumes that we are
already logged in.

=item get_message id

Returns the first 10 lines of a message with a specifik id.

=back

=head1 SUPPORTED MODES

    CONNECT

=head1 SPECIFICS

    - Net::Telnet is called with Telnetmode disabled
    - Some custom procedures are defined
    - close method overrides default method

=head1 AUTHOR

Maarten Wallraf E<lt>perl@2nms.comE<gt>

=cut
