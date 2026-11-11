package Net::UPnP::GW::Gateway;

#-----------------------------------------------------------------
# Net::UPnP::GW::Gateway
#-----------------------------------------------------------------

use strict;
use warnings;

use Net::UPnP::HTTP;
use Net::UPnP::Device;
use Net::UPnP::Service;
use Carp qw(croak);

use vars qw($_DEVICE $_CONNECTION_SERVICE_TYPE $DEVICE_TYPE $WANIPCONNECTION_SERVICE_TYPE $WANPPPCONNECTION_SERVICE_TYPE $WANCOMMONINTERFACECONFIG_SERVICE_TYPE);

$_DEVICE = 'device';
$_CONNECTION_SERVICE_TYPE = 'connection_service_type';

$DEVICE_TYPE = 'urn:schemas-upnp-org:device:InternetGatewayDevice:1';
$WANIPCONNECTION_SERVICE_TYPE = 'urn:schemas-upnp-org:service:WANIPConnection:1';
$WANPPPCONNECTION_SERVICE_TYPE = 'urn:schemas-upnp-org:service:WANPPPConnection:1';
$WANCOMMONINTERFACECONFIG_SERVICE_TYPE = 'urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1';

#------------------------------
# new
#------------------------------

sub new {
	my($class) = shift;
	my %args = @_;
	my($this) = {
		$Net::UPnP::GW::Gateway::_DEVICE => undef,
		$Net::UPnP::GW::Gateway::_CONNECTION_SERVICE_TYPE => $args{connection_service_type},
	};
	bless $this, $class;
}

#------------------------------
# device
#------------------------------

sub setdevice() {
	my($this) = shift;
	if (@_) {
		$this->{$Net::UPnP::GW::Gateway::_DEVICE} = $_[0];
	}
}

sub getdevice() {
	my($this) = shift;
	$this->{$Net::UPnP::GW::Gateway::_DEVICE};
}

#------------------------------
# connection service
#------------------------------

# Service types tried, in order, when no type has been set explicitly.
# Dial-up (PPPoE/PPPoA) routers often provide only WANPPPConnection
# (RT #60372).
sub _connection_service_types {
	return ($Net::UPnP::GW::Gateway::WANIPCONNECTION_SERVICE_TYPE,
		$Net::UPnP::GW::Gateway::WANPPPCONNECTION_SERVICE_TYPE);
}

sub setconnectionservicetype {
	my($this) = shift;
	$this->{$Net::UPnP::GW::Gateway::_CONNECTION_SERVICE_TYPE} = $_[0];
}

sub getconnectionservice {
	my($this) = shift;
	my $dev = $this->getdevice();
	return undef unless $dev;
	my $type = $this->{$Net::UPnP::GW::Gateway::_CONNECTION_SERVICE_TYPE};
	my @types = (defined($type) && length($type)) ? ($type) : _connection_service_types();
	foreach my $service_type (@types) {
		my $service = $dev->getservicebyname($service_type);
		return $service if $service;
	}
	return undef;
}

sub getconnectionservicetype {
	my($this) = shift;
	my $service = $this->getconnectionservice();
	return '' unless $service;
	my $type = $this->{$Net::UPnP::GW::Gateway::_CONNECTION_SERVICE_TYPE};
	return $type if defined($type) && length($type);
	my $dev = $this->getdevice();
	foreach my $service_type (_connection_service_types()) {
		my $found = $dev->getservicebyname($service_type);
		return $service_type if $found && $found == $service;
	}
	return '';
}

sub _connectionaction {
	my($this, $action_name) = @_;
	my $service = $this->getconnectionservice();
	return undef unless $service;
	my $action_res = $service->postaction($action_name);
	return undef unless $action_res->getstatuscode() == 200;
	return $action_res->getargumentlist();
}

#------------------------------
# getstatusinfo
#------------------------------

sub getstatusinfo {
	my($this) = shift;
	my $arg_list = $this->_connectionaction('GetStatusInfo') or return undef;
	return {
		ConnectionStatus => $arg_list->{'NewConnectionStatus'},
		LastConnectionError => $arg_list->{'NewLastConnectionError'},
		Uptime => $arg_list->{'NewUptime'},
	};
}

#------------------------------
# getconnectiontypeinfo
#------------------------------

sub getconnectiontypeinfo {
	my($this) = shift;
	my $arg_list = $this->_connectionaction('GetConnectionTypeInfo') or return undef;
	return {
		ConnectionType => $arg_list->{'NewConnectionType'},
		PossibleConnectionTypes => $arg_list->{'NewPossibleConnectionTypes'},
	};
}

#------------------------------
# getlinklayermaxbitrates (WANPPPConnection only)
#------------------------------

sub getlinklayermaxbitrates {
	my($this) = shift;
	return undef unless $this->getconnectionservicetype() eq $Net::UPnP::GW::Gateway::WANPPPCONNECTION_SERVICE_TYPE;
	my $arg_list = $this->_connectionaction('GetLinkLayerMaxBitRates') or return undef;
	return {
		UpstreamMaxBitRate => $arg_list->{'NewUpstreamMaxBitRate'},
		DownstreamMaxBitRate => $arg_list->{'NewDownstreamMaxBitRate'},
	};
}

#------------------------------
# getexternalipaddress
#------------------------------

sub getexternalipaddress {
	my($this) = shift;
	
	my (
		$dev,
		$wanipcon_service,
		$action_res,
		$arg_list,
		$ipaddr,
	);
	
	$dev = $this->getdevice();
	$wanipcon_service = $this->getconnectionservice();
	unless ($wanipcon_service) {
		return "";
	}
	$action_res = $wanipcon_service->postaction("GetExternalIPAddress");
	if ($action_res->getstatuscode() != 200) {
		return "";
	}
	$arg_list = $action_res->getargumentlist();
	$ipaddr = $arg_list->{'NewExternalIPAddress'};
	
	return $ipaddr;
}

#------------------------------
# getportmappingnumberofentries
#------------------------------

sub getportmappingnumberofentries {
	my($this) = shift;

	my (
		$dev,
		$wanipcon_service,
		$query_res,
	);
	
	$dev = $this->getdevice();
	$wanipcon_service = $this->getconnectionservice();
	unless ($wanipcon_service) {
		return 0;
	}
	
        $query_res = $wanipcon_service->postquery("PortMappingNumberOfEntries");

	if ($query_res->getstatuscode() != 200) {
		return 0;
	}

        if( $query_res->getvalue() =~ /^(\d+)$/ ) {
            return $1;
        } else {
            return scalar($this->getportmappingentries());
        }
}


#------------------------------
# getportmapping
#------------------------------

sub getportmappingentries {
	my($this) = shift;
	my %args = (max_entries => 1024, timeout => 30, @_);
	croak 'Invalid mapping entry limit' unless defined($args{max_entries})
		&& $args{max_entries} =~ /\A\d+\z/ && POSIX::isfinite(0 + $args{max_entries}) && $args{max_entries} > 0;
	croak 'Invalid mapping timeout' unless defined($args{timeout})
		&& $args{timeout} =~ /\A\d+(?:\.\d+)?\z/ && POSIX::isfinite(0 + $args{timeout}) && $args{timeout} > 0;
	$this->{error} = '';
	my $deadline = Net::UPnP::HTTP::_now() + $args{timeout};
	
	my (
		@port_mapping,
		$dev,
		$port_mapping_num,
		$wanipcon_service,
		$n,
		%req_arg,
		$action_res,
		$arg_list,
		$ipaddr,
	);
	
	$dev = $this->getdevice();
	$wanipcon_service = $this->getconnectionservice();
	unless ($wanipcon_service) {
		return @port_mapping;
	}
	
        $n = 0;
        while ($n < $args{max_entries}) {
		if (Net::UPnP::HTTP::_now() >= $deadline) {
			$this->{error} = 'Port mapping deadline exceeded';
			last;
		}
		%req_arg = (
				'NewPortMappingIndex' => $n,
			);
	
		$action_res = $wanipcon_service->postaction("GetGenericPortMappingEntry", \%req_arg, {deadline => $deadline});
		#print "[$n]" .$action_res->getstatuscode()  . "\n";
		#print %req_arg;
		if ($action_res->getstatuscode() != 200) {
			$this->{error} = 'Port mapping request failed' if !$action_res->getstatuscode();
			last;
		}
		$arg_list = $action_res->getargumentlist();
		#print $arg_list;
		push(@port_mapping, $arg_list);
                ++$n;
	}
	if ($n == $args{max_entries}) {
		$this->{error} = 'Port mapping entry limit reached';
	}
	
	return @port_mapping;
}

sub geterror { $_[0]->{error} || '' }

# deprecated method - mapped to new name
sub getportmappingentry { getportmappingentries(@_); }


#------------------------------
# addportmapping
#------------------------------

sub addportmapping {
	my($this) = shift;
	my %args = (
		NewRemoteHost => '',
		NewExternalPort => '',	
		NewProtocol => '',
		NewInternalPort => '',
		NewInternalClient => '',
		NewEnabled => 1,
		NewPortMappingDescription => '',
		NewLeaseDuration => 0,
		@_,
	);
	
	my (
		$dev,
		$wanipcon_service,
		$action_res,
		$arg_list,
		$ipaddr,
		%req_arg,
	);
	
	$dev = $this->getdevice();
	$wanipcon_service = $this->getconnectionservice();
	unless ($wanipcon_service) {
		return 0;
	}
	
	%req_arg = (
			'NewRemoteHost' => $args{NewRemoteHost},
			'NewExternalPort' => $args{NewExternalPort},
			'NewProtocol' => $args{NewProtocol},
			'NewInternalPort' => $args{NewInternalPort},
			'NewInternalClient' => $args{NewInternalClient},
			'NewEnabled' => $args{NewEnabled},
			'NewPortMappingDescription' => $args{NewPortMappingDescription},
			'NewLeaseDuration' => $args{NewLeaseDuration},
		);
		
	$action_res = $wanipcon_service->postaction("AddPortMapping", \%req_arg);
	if ($action_res->getstatuscode() != 200) {
		return 0;
	}
	return 1;
}

#------------------------------
# deleteportmapping
#------------------------------

sub deleteportmapping {
	my($this) = shift;
	my %args = (
		NewRemoteHost => '',
		NewExternalPort => '',	
		NewProtocol => '',
		@_,
	);
	
	my (
		$dev,
		$wanipcon_service,
		$action_res,
		$arg_list,
		$ipaddr,
		%req_arg,
	);
	
	$dev = $this->getdevice();
	$wanipcon_service = $this->getconnectionservice();
	unless ($wanipcon_service) {
		return 0;
	}
	
	%req_arg = (
			'NewRemoteHost' => $args{NewRemoteHost},
			'NewExternalPort' => $args{NewExternalPort},
			'NewProtocol' => $args{NewProtocol},
		);
		
	$action_res = $wanipcon_service->postaction("DeletePortMapping", \%req_arg);
	if ($action_res->getstatuscode() != 200) {
		return 0;
	}
	return 1;
}

#------------------------------
# gettotalbytesreceived
#------------------------------

sub gettotalbytesreceived {
	my($this) = shift;
	
	my (
		$dev,
		$wanconif_service,
		$action_res,
		$arg_list,
		$totalBytes,
	);
	
	$dev = $this->getdevice();
	$wanconif_service = $dev->getservicebyname($Net::UPnP::GW::Gateway::WANCOMMONINTERFACECONFIG_SERVICE_TYPE);
	unless ($wanconif_service) {
		return "";
	}
	$action_res = $wanconif_service->postaction("GetTotalBytesReceived");
	if ($action_res->getstatuscode() != 200) {
		return "";
	}
	$arg_list = $action_res->getargumentlist();
	$totalBytes = $arg_list->{'NewTotalBytesReceived'};
	
	return $totalBytes;
}

# Backward-compatible alias for the historical misspelling (RT #123509).
{ no warnings 'once'; *gettotalbytesrecieved = \&gettotalbytesreceived; }

#------------------------------
# gettotalbytessent
#------------------------------

sub gettotalbytessent {
	my($this) = shift;

	my (
		$dev,
		$wanconif_service,
		$action_res,
		$arg_list,
		$totalBytes,
	);

	$dev = $this->getdevice();
	$wanconif_service = $dev->getservicebyname($Net::UPnP::GW::Gateway::WANCOMMONINTERFACECONFIG_SERVICE_TYPE);
	unless ($wanconif_service) {
		return "";
	}
	$action_res = $wanconif_service->postaction("GetTotalBytesSent");
	if ($action_res->getstatuscode() != 200) {
		return "";
	}
	$arg_list = $action_res->getargumentlist();
	$totalBytes = $arg_list->{'NewTotalBytesSent'};

	return $totalBytes;
}

1;

__END__

=head1 NAME

Net::UPnP::GW::Gateway - Perl extension for UPnP.

=head1 SYNOPSIS

        use Net::UPnP::ControlPoint;
        use Net::UPnP::GW::Gateway;
        
        my $obj = Net::UPnP::ControlPoint->new();
        
        @dev_list = ();
        while (@dev_list <= 0 || $retry_cnt > 5) {
        #	@dev_list = $obj->search(st =>'urn:schemas-upnp-org:device:InternetGatewayDevice:1', mx => 10);
                @dev_list = $obj->search(st =>'upnp:rootdevice', mx => 3);
                $retry_cnt++;
        } 
        
        $devNum= 0;
        foreach $dev (@dev_list) {
                my $device_type = $dev->getdevicetype();
                if  ($device_type ne 'urn:schemas-upnp-org:device:InternetGatewayDevice:1') {
                        next;
                }
                print "[$devNum] : " . $dev->getfriendlyname() . "\n";
                my $gwdev = Net::UPnP::GW::Gateway->new();
                $gwdev->setdevice($dev);
                # WANIPConnection, or WANPPPConnection on dial-up routers
                next unless $gwdev->getconnectionservice();
                print "\tExternalIPAddress = " . $gwdev->getexternalipaddress() . "\n";
                print "\tPortMappingNumberOfEntries = " . $gwdev->getportmappingnumberofentries() . "\n";
                @port_mapping = $gwdev->getportmappingentries();
                $port_num = 0;
                foreach $port_entry (@port_mapping) {
                        $port_map_name = $port_entry->{'NewPortMappingDescription'};
                        if (length($port_map_name) <= 0) {
                                $port_map_name = "(No name)";
                        }
                        print "  [$port_num] : $port_map_name\n";
                        foreach $name ( keys %{$port_entry} ) {
                                print "    $name = $port_entry->{$name}\n";
                        }
                        $port_num++;
                }
        }

=head1 DESCRIPTION

The package is an extension UPnP/GW.

=head1 METHODS

=over 4

=item B<new> - create new Net::UPnP::GW::Gateway.

    $mservier = Net::UPnP::GW::Gateway();

Creates a new object. Read `perldoc perlboot` if you don't understand that.

The new object is not associated with any UPnP devices. Please use setdevice() to set the device.


    $gw = Net::UPnP::GW::Gateway->new(connection_service_type => $type);

By default the gateway uses the C<WANIPConnection:1> service and falls back to
C<WANPPPConnection:1>, which dial-up (PPPoE/PPPoA) routers often provide
instead. Pass C<connection_service_type> to use one service type only.

=item B<setconnectionservicetype> - select the WAN connection service type.

    $gw->setconnectionservicetype('urn:schemas-upnp-org:service:WANPPPConnection:1');

Use only the given service type. Pass C<undef> to restore the default
(WANIPConnection, then WANPPPConnection).

=item B<getconnectionservice> - get the WAN connection service.

    $service = $gw->getconnectionservice();

Returns the L<Net::UPnP::Service> used for the external IP address and port
mapping methods, or C<undef> if the device has none.

=item B<getconnectionservicetype> - get the WAN connection service type.

    $type = $gw->getconnectionservicetype();

Returns the service type of getconnectionservice(), or an empty string.

=item B<getstatusinfo> - get the connection status.

    $info = $gw->getstatusinfo();

Returns a hash reference with C<ConnectionStatus>, C<LastConnectionError> and
C<Uptime>, or C<undef> on failure.

=item B<getconnectiontypeinfo> - get the connection type.

    $info = $gw->getconnectiontypeinfo();

Returns a hash reference with C<ConnectionType> and
C<PossibleConnectionTypes>, or C<undef> on failure.

=item B<getlinklayermaxbitrates> - get the link layer bit rates.

    $info = $gw->getlinklayermaxbitrates();

Returns a hash reference with C<UpstreamMaxBitRate> and
C<DownstreamMaxBitRate>. This action exists only in WANPPPConnection, so
C<undef> is returned when the gateway uses WANIPConnection.
=item B<setdevice> - set a UPnP devices

    $gw->setdevice($dev);

Set a device to the object.

=item B<getexternalipaddress> - External IP address

    $gw->getexternalipaddress();

Get the external IP address.

=item B<getportmappingnumberofentries> - PortMappingNumberOfEntries

    $gw->getportmappingnumberofentries();

Get the number of the port mapping entries.

=item B<getportmappingentries> - PortMappingEntry

    $gw->getportmappingentries();

Get the port mapping entries.

=item B<addportmapping> - add new port mapping.

    $result = gw->addportmapping(
                              NewRemoteHost # '',
                              NewExternalPort # '',	
                              NewProtocol # '',
                              NewInternalPort # '',
                              NewInternalClient # '',
                              NewEnabled #1,
                              NewPortMappingDescription # '',
                              NewLeaseDuration # 0);

Add a new specified port mapping.

=item B<deleteportmapping> - delete a port mapping.

    $result = gw->deleteportmapping(
                              NewRemoteHost # '',
                              NewExternalPort # '',	
                              NewProtocol # '');

Delete the specified port mapping.

=item B<gettotalbytesreceived> - Total received bytes.

    $gw->gettotalbytesreceived();

Get the total received bytes. The misspelled name C<gettotalbytesrecieved>
is kept as an alias for backward compatibility.

=back

=head1 AUTHOR

Satoshi Konno
skonno@cybergarage.org

CyberGarage
http://www.cybergarage.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Satoshi Konno

It may be used, redistributed, and/or modified under the terms of BSD License.

=cut
