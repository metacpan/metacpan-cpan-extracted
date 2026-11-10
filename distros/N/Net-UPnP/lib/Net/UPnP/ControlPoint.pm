package Net::UPnP::ControlPoint;

#-----------------------------------------------------------------
# Net::UPnP::ControlPoint
#-----------------------------------------------------------------

use strict;
use warnings;

use Socket;
use Carp qw(croak);

use Net::UPnP;
use Net::UPnP::HTTP;
use Net::UPnP::Device;

#------------------------------
# new
#------------------------------

sub new {
	my($class) = shift;
	my($this) = {};
	bless $this, $class;
}

#------------------------------
# search
#------------------------------

sub search {
	my($this) = shift;
	my %args = (
		st => 'upnp:rootdevice',	
		mx => 3,
		max_packets => 256,
		max_devices => 64,
		allowed_addresses => [],
		@_,
	);
	$this->{error} = '';
	my $extra_addresses = Net::UPnP::HTTP::_address_list($args{allowed_addresses});
	croak 'Invalid discovery mx' unless defined($args{mx}) && $args{mx} =~ /\A\d+(?:\.\d+)?\z/;
	croak 'Invalid discovery mx' unless POSIX::isfinite(0 + $args{mx}) && POSIX::isfinite(2 * $args{mx});
	foreach my $key (qw(max_packets max_devices)) {
		croak "Invalid discovery $key" unless defined($args{$key})
			&& $args{$key} =~ /\A\d+\z/ && POSIX::isfinite(0 + $args{$key}) && $args{$key} > 0;
	}
	return () unless $args{mx} > 0;
	my $deadline = Net::UPnP::HTTP::_now() + $args{mx} * 2;
	my ($packets, %seen_location) = (0);
	my(
		@dev_list,
		$ssdp_header,
		$ssdp_mcast,
		$rin,
		$rout,
		$ssdp_res_msg,
		$dev_location,
		$dev_addr,
		$dev_port,
		$dev_path,
		$http_req,
		$post_res,
		$post_content,
		$key,
		$dev,
		);
		
$ssdp_header = <<"SSDP_SEARCH_MSG";
M-SEARCH * HTTP/1.1
Host: $Net::UPnP::SSDP_ADDR:$Net::UPnP::SSDP_PORT
Man: "ssdp:discover"
ST: $args{st}
MX: $args{mx}

SSDP_SEARCH_MSG

	$ssdp_header =~ s/\r//g;
	$ssdp_header =~ s/\n/\r\n/g;

	socket(my $ssdp_sock, AF_INET, SOCK_DGRAM, getprotobyname('udp')) or return ();
	$ssdp_mcast = sockaddr_in($Net::UPnP::SSDP_PORT, inet_aton($Net::UPnP::SSDP_ADDR));

	unless (send($ssdp_sock, $ssdp_header, 0, $ssdp_mcast)) {
		close($ssdp_sock);
		return ();
	}

	if ($Net::UPnP::DEBUG) {
		print "$ssdp_header\n";
 	}

	@dev_list = ();
	
	$rin = '';
	vec($rin, fileno($ssdp_sock), 1) = 1;
	while (1) {
		my $remaining = $deadline - Net::UPnP::HTTP::_now();
		last if $remaining <= 0;
		last unless select($rout = $rin, undef, undef, $remaining) > 0;
		my $peer = recv($ssdp_sock, $ssdp_res_msg, 4096, 0);
		last unless defined $peer;
		my (undef, $peer_address) = sockaddr_in($peer);
		my $peer_ip = inet_ntoa($peer_address);
		my ($first) = unpack('C4', $peer_address);
		my @allowed = @$extra_addresses;
		# LAN/private and link-local peers are valid UPnP devices. Loopback,
		# unspecified and multicast/reserved sources require explicit trust.
		push @allowed, $peer_ip if $first > 0 && $first != 127 && $first < 224;
		if (++$packets > $args{max_packets}) {
			$this->{error} = 'Discovery packet limit exceeded';
			last;
		}
		
		print "$ssdp_res_msg" if ($Net::UPnP::DEBUG);
		
		unless ($ssdp_res_msg =~ m/LOCATION[ :]+(.*)\r/i) {
			next;
		}		
		$dev_location = $1;
		# A rejected advertisement from another peer must not poison the
		# legitimate device's later advertisement of the same URL.
		next if $seen_location{$peer_ip . "\0" . $dev_location}++;
		print "dev_location=$dev_location\n" if ($Net::UPnP::DEBUG);
                unless ($dev_location =~ m{http://([0-9a-z.-]+)(?::(\d+))?/(.*)}i) {
                        print "bad dev_location: $dev_location\n" if ($Net::UPnP::DEBUG);
			next;
		}
		$dev_addr = $1;
		$dev_port = $2 || 80;
		$dev_path = '/' . $3;
		print "dev_addr=$dev_addr dev_port=$dev_port dev_path=$dev_path\n" if ($Net::UPnP::DEBUG);
		
		$http_req = Net::UPnP::HTTP->new(deadline => $deadline, allowed_addresses => \@allowed);
		$post_res = $http_req->post($dev_addr, $dev_port, "GET", $dev_path, "", "");
		unless ($post_res) {
			$this->{error} = $http_req->geterror();
			next;
		}
		
		if ($Net::UPnP::DEBUG) {
			print $post_res->getstatus() . "\n";
			print $post_res->getheader() . "\n";
			print $post_res->getcontent() . "\n";
		}
 
 		$post_content = $post_res->getcontent();

		$dev = Net::UPnP::Device->new();
		$dev->setallowedaddresses(\@allowed);
 		$dev->setssdp($ssdp_res_msg);
		$dev->setdescription($post_content);
	
		if ($Net::UPnP::DEBUG) {
	 		print "ssdp = $ssdp_res_msg\n";
	 		print "description = $post_content\n";
	 	}

		push(@dev_list, $dev);
		if (@dev_list >= $args{max_devices}) {
			$this->{error} = 'Discovery device limit reached';
			last;
		}
		
	}

	close($ssdp_sock);
	
	@dev_list;
}

sub geterror { $_[0]->{error} || '' }

1;

__END__

=head1 NAME

Net::UPnP::ControlPoint - Perl extension for UPnP control point.

=head1 SYNOPSIS

    use Net::UPnP::ControlPoint;

    my $obj = Net::UPnP::ControlPoint->new();

    @dev_list = $obj->search(st =>'upnp:rootdevice', mx => 3);

    $devNum= 0;
    foreach $dev (@dev_list) {
        $device_type = $dev->getdevicetype();
        if  ($device_type ne 'urn:schemas-upnp-org:device:MediaServer:1') {
            next;
        }
        print "[$devNum] : " . $dev->getfriendlyname() . "\n";
        unless ($dev->getservicebyname('urn:schemas-upnp-org:service:ContentDirectory:1')) {
            next;
        }
        $condir_service = $dev->getservicebyname('urn:schemas-upnp-org:service:ContentDirectory:1');
        unless (defined($condir_service)) {
            next;
        }
        %action_in_arg = (
                'ObjectID' => 0,
                'BrowseFlag' => 'BrowseDirectChildren',
                'Filter' => '*',
                'StartingIndex' => 0,
                'RequestedCount' => 0,
                'SortCriteria' => '',
            );
        $action_res = $condir_service->postcontrol('Browse', \%action_in_arg);
        $action_out_arg = $action_res->getargumentlist();
        unless ($action_out_arg->{'Result'}) {
            next;
        }
        $result = $action_out_arg->{'Result'};
        while ($result =~ m/<dc:title>(.*?)<\/dc:title>/sgi) {
            print "\t$1\n";
        }
        $devNum++;
    }

=head1 DESCRIPTION

The package can search UPnP devices in the local network and get the device list of L<Net::UPnP::Device>.

=head1 METHODS

=over 4

=item B<new> - create new Net::UPnP::ControlPoint

    $ctrlPoint = Net::UPnP::ControlPoint();

Creates a new object. Read `perldoc perlboot` if you don't understand that.

=item B<search> - search UPnP devices

    @device_list = $ctrlPoint->search();

    @device_list = $ctrlPoint->search(
                [st => $search_target], # 'upnp:rootdevice'
                [mx => $maximum_wait] # 3
                );

Search UPnP devices and return the device list. Please see L<Net::UPnP::Device> too.

=back

=head1 SEE ALSO

L<Net::UPnP::Device>

=head1 AUTHOR

Satoshi Konno
skonno@cybergarage.org

CyberGarage
http://www.cybergarage.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Satoshi Konno
	
It may be used, redistributed, and/or modified under the terms of BSD License.

=cut
