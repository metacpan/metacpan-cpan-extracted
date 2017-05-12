package Net::Radius::SSG;

# $Revision: 34 $

#use 5.008001;
use strict;
use warnings;
use Net::Radius::Dictionary;
use Net::Radius::Packet;
use Net::Inet;
use Net::UDP;
use Fcntl;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
use AutoLoader qw(AUTOLOAD);

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Radius::SSG ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	SSG_ACCOUNT_PING SSG_ACCOUNT_LOGON 
	SSG_ACCOUNT_LOGOFF SSG_SERVICE_LOGON
	SSG_SERVICE_LOGOFF
);

$VERSION = '0.04';


# Preloaded methods go here.

use constant VSA_CISCO => 9;
use constant SECRET => 'cisco';
use constant SSG_ACCOUNT_PING 	=> "\004 &";
use constant SSG_ACCOUNT_LOGON 	=> "\001";
use constant SSG_ACCOUNT_LOGOFF => "\002";
use constant SSG_SERVICE_LOGON 	=> "\013";
use constant SSG_SERVICE_LOGOFF => "\014";
use constant DEFAULT_TIMEOUT	=> 10;

sub new {
	my $class	= shift;
	my $ssg_ip	= shift;
	my $ssg_port	= shift;
	my $secret	= shift;
	my $dictionary	= shift;

	my $self		= { };
	if (!defined $ssg_ip) {
		die "Please specify an IP for the SSG.";
	}
	$self->{'SSG_IP'}	= $ssg_ip;
	if (!defined $ssg_port) {
		die "Please specify a port for the SSG.";
	}
	$self->{'SSG_PORT'} = $ssg_port;
	if (!defined $secret) {
		die "Please specify a shared secret for the SSG.";
	}
	$self->{'SECRET'} = $secret;
	if (!defined $dictionary) {
		die "Please specify a dictionary file";
	}
	if ( ! -r $dictionary) {
		die "Unable to read dictionary file: $dictionary";
	}

	$self->{'DICTIONARY'} = new Net::Radius::Dictionary($dictionary);

	$self->{'SOCKET'} = &create_udp_handle($ssg_ip,$ssg_port);

	bless $self,$class;
	return $self;
}

sub create_udp_handle {
	my $server	= shift;
	my $port	= shift;
	my $udp		= new Net::UDP $server, $port;
	$udp->bind;
	$udp->fcntl(F_SETFL, $udp->fcntl(F_GETFL,0) | O_NONBLOCK) or die "Failed to create a Non-blocking socket: $!";
	return $udp;
}

sub action {
	my $self	= shift;
	my $action	= shift;
	my $values	= shift;
	my $data;

	my $packet = new Net::Radius::Packet($self->{DICTIONARY});
	$packet->set_authenticator('1234w6t890123a5c');

	if ($action eq SSG_ACCOUNT_PING) {
		&account_ping($packet,$values->{user_ip});
	} elsif ($action eq SSG_ACCOUNT_LOGON) {
		&account_logon($packet,$values->{user_ip},$values->{user_id},$values->{password}, $self->{SECRET});
	} elsif ($action eq SSG_ACCOUNT_LOGOFF) {
		&account_logoff($packet,$values->{user_ip},$values->{user_id});
	} elsif ($action eq SSG_SERVICE_LOGON) {
		&service($packet,$values->{user_ip},$values->{service}, SSG_SERVICE_LOGON);
	} elsif ($action eq SSG_SERVICE_LOGOFF) {
		&service($packet,$values->{user_ip},$values->{service}, SSG_SERVICE_LOGOFF);
	} else {
		die ("Unknown action");
	}
	&send_packet($self->{SOCKET},$packet);
	my $reply = &receive_reply($self->{SOCKET}, $values->{timeout});
	my $rp = new Net::Radius::Packet $self->{DICTIONARY}, $reply;
	return $rp;
}

sub receive_reply {
	my $udp		= shift;
	my $timeout 	= shift;
	$timeout = DEFAULT_TIMEOUT if (!defined $timeout);
	my ($rec, $whence);
	my $nfound = $udp->select(1, 0, 1, $timeout);
	if ($nfound > 0) {
		$rec = $udp->recv(undef, undef, $whence);
		return $rec;
	}
}

sub send_packet {
	my $udp		= shift;
	my $packet	= shift;
	$udp->send($packet->pack());
}


sub account_ping {
	my $packet	= shift;
	my $user_ip	= shift;
	$packet->set_code('Access-Request');
	$packet->set_identifier(57);
	$packet->set_vsattr(VSA_CISCO,'Account-Info','S'.$user_ip);
	$packet->set_vsattr(VSA_CISCO,'Command-Code', SSG_ACCOUNT_PING);
}

sub account_logon {
	my $packet	= shift;
	my $user_ip	= shift;
	my $user_id	= shift;
	my $password	= shift;
	my $secret	= shift;
	$packet->set_code('Access-Request');
	$packet->set_identifier(57);
	$packet->set_attr('User-Name',$user_id);
	$packet->set_password($password,$secret);
	$packet->set_vsattr(VSA_CISCO,'Account-Info','S'.$user_ip);
	$packet->set_vsattr(VSA_CISCO,'Command-Code', SSG_ACCOUNT_LOGON."$user_id");
}

sub account_logoff {
	my $packet	= shift;
	my $user_ip	= shift;
	my $user_id	= shift;
	$packet->set_code('Access-Request');
	$packet->set_identifier(57);
	$packet->set_attr('User-Name',$user_id);
	$packet->set_vsattr(VSA_CISCO,'Account-Info','S'.$user_ip);
	$packet->set_vsattr(VSA_CISCO,'Command-Code', SSG_ACCOUNT_LOGOFF."$user_id");
}

sub service {
	my $packet	= shift;
	my $user_ip	= shift;
	my $service	= shift;
	my $action	= shift;
	$packet->set_code('Access-Request');
	$packet->set_identifier(23);
	$packet->set_vsattr(VSA_CISCO,'Account-Info','S'.$user_ip);
	$packet->set_vsattr(VSA_CISCO,'Command-Code', $action."$service");
}




# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::Radius::SSG - Perl extension for communicating with a Cisco SSG (Service Selection Gateway) router.

=head1 SYNOPSIS

  use Net::Radius::SSG;
  my $ssg = new Net::Radius::SSG($ssg_ip, $ssg_port, $ssg_shared_secret, $dictionary);
  my $radius_packet = $ssg->action(SSG_ACCOUNT_LOGON, 
  	{ user_ip => '1.2.3.4',
  	  user_id => 'testuser',
	  password => 'password' });
  if ($radius_packet->code eq 'Access-Accept') {
	  print "User successfully logged on to the SSG\n";
  }
  ...

=head1 DESCRIPTION

Net::Radius::SSG is for communicating with a Cisco SSG router via the Service Selection Dashboard (SSD) protocol which is implemented over RADIUS.  This module requires Net::Radius and Net::UDP.

=head2 new

$ssg_object = new Net::Radius::SSG($ip,$port,$secret, $dictionary_file);

Creates a new SSG (Service Selection Gateway) object.  Requires the SSG IP address (or hostname), the Radius port that the SSG is listening on, the Radius shared secret and the location of a Merit dictionary file.  Please see the Net::Radius::Dictionary documentation for further information on dictionary files.

=head2 action

my $radius_packet = $ssg_object->action(ACTION, \%params);

Requires an action (one of SSG_ACCOUNT_LOGON, SSG_ACCOUNT_LOGOFF, SSG_ACCOUNT_PING, SSG_SERVICE_LOGON or SSG_SERVICE_LOGOFF) plus a hash containing the parameters.  The action function returns a Net::Radius::Packet object.  The params hash differs for each action.  All actions understand the {timeout => SECONDS} option.  The timeout parameter specifies how long the action function will wait for a reply from the SSG.

The list of parameters are:
user_id => $username,
user_ip => $ip_address,
service => $service_name,
timeout => $seconds.


The various actions are:

=head2 SSG_ACCOUNT_PING

This action sends an 'account ping' command code to the SSG, used to return the username of the person logged in on a particular IP address.

$rp = $ssg_object->action(SSG_ACCOUNT_PING, { user_ip => '1.2.3.4' });

if ($rp->code eq 'Access-Accept') {
	
	if (defined $rp->attr('User-Name')) {
	
		print $rp->attr('User-Name');
	
	}

}

=head2 SSG_ACCOUNT_LOGON

This action sends an 'account logon' command code to the SSG.  Requires the user_id, user_ip and password values to be set.

=head2 SSG_ACCOUNT_LOGOFF

This action sends an 'account logoff' command code to the SSG.  Requires the user_id and user_ip values to be set.

=head2 SSG_SERVICE_LOGON

This action sends a 'service logon' command code to the SSG.  Requires the user_ip and service values to be supplied.

=head2 SSG_SERVICE_LOGOFF

This action sends a 'service logoff' command code to the SSG.  Requires the user_ip and service values to be supplied.

=head2 EXPORT

SSG_ACCOUNT_PING SSG_ACCOUNT_LOGON SSG_ACCOUNT_LOGOFF 
SSG_SERVICE_LOGON SSG_SERVICE_LOGOFF



=head1 SEE ALSO

Net::Radius::Packet, Net::Radius::Dictionary, Net::UDP

=head1 AUTHOR

Chris Myers, E<lt>c.myers@its.uq.edu.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Chris Myers

This software comes with no warranty whatsoever and the author is not
liable for the outcomes of the use of this software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
