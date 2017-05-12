package NetworkInfo::Discovery::Sniff;

use vars qw(@ISA);
use strict;
use warnings;

use NetworkInfo::Discovery::Detect;
@ISA = ("NetworkInfo::Discovery::Detect");

use Net::Pcap;
use NetPacket::Ethernet qw(:types);
use NetPacket::IP;
use NetPacket::TCP;
use NetPacket::UDP;
use NetPacket::ARP qw(:ALL);
use NetPacket::ICMP qw(:ALL); 


sub new {
    my $classname  = shift;
    my $self       = $classname->SUPER::new(@_);
    my %args = @_;

    # set defaults
    $self->timeout(60);
    $self->maxcapture(10);
    $self->snaplen(1500);
    $self->promisc(1);
    
    # use user settings that were passed in.
    # for all args, see if we can autoload them
    foreach my $attr (keys %args) {
	if ($self->can($attr) ) {
	    $self->$attr( $args{$attr} );
	} else {
	    print "error calling NetworkInfo::Discovery::Sniff-> $attr (  $args{$attr} ) : no method $attr \n";
	}
    }

    return $self;
} 

sub do_it {
    my $self = shift;
    
    $self->capture;
    $self->process_ip_packets;

    return $self->get_interfaces;
}

sub capture {
    my $self = shift;

    $self->{'device'} = Net::Pcap::lookupdev(\$self->{'error'});
    defined $self->{'error'} 
	&& die 'Unable to determine network device for monitoring - ', $self->{'error'};

    Net::Pcap::lookupnet($self->device, \$self->{'address'}, \$self->{'netmask'}, \$self->{'error'})
	&&  die 'Unable to look up device information for ', $self->device, ' - ', $self->error;

    $self->realmask(join('.',unpack("C4",pack("N",$self->netmask))) );
    $self->realip(join('.',unpack("C4",pack("N",$self->address))) );

    $self->{'object'} = Net::Pcap::open_live(
		    $self->device, 
		    $self->snaplen, 
		    $self->promisc, 
		    $self->timeout, 
		    \$self->{'error'}
		);

    defined $self->{'object'} 
	|| die 'Unable to create packet capture on device ', $self->device, ' - ', $self->{'error'}; 

    Net::Pcap::compile( $self->object, \$self->{'filter'}, '', 0, $self->netmask) 
	&& die 'Unable to compile packet capture filter';

    Net::Pcap::setfilter($self->object, $self->filter) 
	&& die 'Unable to set packet capture filter';

    Net::Pcap::loop($self->object, $self->maxcapture, \&get_packets, \@{$self->{'packetlist'}}) ;
	# ||   die 'Unable to perform packet capture';
    
    Net::Pcap::close($self->object);

}

sub get_packets {
    #    print "get_pkt\n" if $DEBUG ;
    my ( $arg , $hdr, $pkt) = @_ ;
    push ( @$arg , $pkt ) ;
}

sub process_ip_packets {
    my $self = shift;

    foreach my $packet ( @{$self->{'packetlist'}} ) {
        my $ether_obj = NetPacket::Ethernet->decode($packet);
        my $ether_data = $ether_obj->{"data"};
    
	if ($ether_obj->{type} == ETH_TYPE_ARP ) {
	    my $arp_data = NetPacket::ARP->decode($ether_data);

	    if ($arp_data->{opcode} == ARP_OPCODE_REQUEST) {
#		my $shost = new NetworkInfo::Discovery::Host (ipaddress => hex2ip($arp_data->{spa}),
#						      does_ethernet => "yes",
#						      does_arp => "yes",
#						      mac => hex2mac($arp_data->{sha}) );
#		$self->add_host($shost);
		$self->add_interface(
		    {
		    ip=> hex2ip($arp_data->{spa}),
		    mac => hex2mac($arp_data->{sha}) ,
		    mask=> $self->realmask,
		    }
		);

	    } elsif ($arp_data->{opcode} == ARP_OPCODE_REPLY) {
#		my $shost = new NetworkInfo::Discovery::Host (ipaddress => hex2ip($arp_data->{spa}),
#						      does_ethernet => "yes",
#						      does_arp => "yes",
#						      mac	=> hex2mac($arp_data->{sha}) );
#		my $dhost = new NetworkInfo::Discovery::Host (ipaddress => hex2ip($arp_data->{tpa}),
#						      does_ethernet => "yes",
#						      does_arp => "yes",
#						      mac	=> hex2mac($arp_data->{tha}) );
#		$self->add_host($shost,$dhost);
		$self->add_interface(
		    {
			ip=> hex2ip($arp_data->{spa}), 
			mac=> hex2mac($arp_data->{sha}),
			mask=> $self->realmask,
		    } ,
		    { 
			ip=> hex2ip($arp_data->{tpa}),
			mac => hex2mac($arp_data->{tha}),
			mask=> $self->realmask,
		    } 
		);

	    } elsif ($arp_data->{opcode} == RARP_OPCODE_REQUEST) {
		print "got RARP_OPCODE_REQUEST\n";
	    } elsif ($arp_data->{opcode} == RARP_OPCODE_REPLY) {
		print "got RARP_OPCODE_REPLY\n";
	    }
    
        } elsif ($ether_obj->{type} == ETH_TYPE_IP ) {
	    ## for IP packets
       
	    my $ip = NetPacket::IP->decode($ether_data);
        
	    if ($ip->{"proto"}  == 6 ) {
		# TCP Stuff
	        my ($sports, $dports); 
		my $tcp = NetPacket::TCP->decode($ip->{'data'});
		push @$sports, $tcp->{'src_port'};
		push @{$dports}, $tcp->{'dest_port'};

#		my $shost = new NetworkInfo::Discovery::Host (ipaddress => "$ip->{'src_ip'}",
#						      does_ethernet => "yes",
#								does_tcp=> "yes");
#		my $dhost = new NetworkInfo::Discovery::Host (ipaddress => "$ip->{'dest_ip'}",
#						      does_ethernet => "yes",
#								does_tcp=> "yes");
#
#		$self->add_host($shost,$dhost);
#


		$self->add_interface(
		    {
			ip=>"$ip->{'src_ip'}",
			mask=>( ($self->matches_subnet($ip->{'src_ip'})) ? $self->realmask : ""),
		    },
		    {
			ip=>"$ip->{'dest_ip'}",
			mask=>( ($self->matches_subnet($ip->{'dest_ip'})) ? $self->realmask : ""),
		    }
		);

            } elsif ($ip->{"proto"}  == 17 ) {
	       # UDP Stuff
	       my $udp = NetPacket::UDP->decode($ip->{'data'});
    
	       my ($sports, $dports); 
	       push @$sports, $udp->{'src_port'};
	       push @{$dports}, $udp->{'dest_port'};

#		my $shost = new NetworkInfo::Discovery::Host (ipaddress => "$ip->{'src_ip'}",
#						      does_ethernet => "yes",
#								does_udp=> "yes");
#		my $dhost = new NetworkInfo::Discovery::Host (ipaddress => "$ip->{'dest_ip'}",
#						      does_ethernet => "yes",
#								does_udp=> "yes");
#
#		$self->add_host($shost,$dhost);
		$self->add_interface(
		    {
			ip=>$ip->{'src_ip'},
			mask=>( ($self->matches_subnet($ip->{'src_ip'})) ? $self->realmask : ""),
		    },
		    {
			ip=>$ip->{'dest_ip'},
			mask=>( ($self->matches_subnet($ip->{'dest_ip'})) ? $self->realmask : ""),
		    },
		);
    
            } elsif ($ip->{"proto"}  == 1 ) {
		# ICMP stuff here
		my $icmp = NetPacket::ICMP->decode($ip->{'data'});
    
		my $type;
		if ($icmp->{type} ==  ICMP_ECHOREPLY ) {
		    $type = "ICMP_ECHOREPLY";
		} elsif ($icmp->{type} ==  ICMP_UNREACH ) {
		    $type = "ICMP_UNREACH";
		} elsif ($icmp->{type} ==  ICMP_SOURCEQUENCH ) {
		    $type = "ICMP_SOURCEQUENCH";
		} elsif ($icmp->{type} ==  ICMP_REDIRECT ) {
		    $type = "ICMP_REDIRECT";
		} elsif ($icmp->{type} ==  ICMP_ECHO ) {
		    $type = "ICMP_ECHO";
		} elsif ($icmp->{type} ==  ICMP_ROUTERADVERT ) {
		    $type = "ICMP_ROUTERADVERT";
		} elsif ($icmp->{type} ==  ICMP_ROUTERSOLICIT ) {
		    $type = "ICMP_ROUTERSOLICIT";
		} elsif ($icmp->{type} ==  ICMP_TIMXCEED ) {
		    $type = "ICMP_TIMXCEED";
		} elsif ($icmp->{type} ==  ICMP_PARAMPROB ) {
		    $type = "ICMP_PARAMPROB";
		} elsif ($icmp->{type} ==  ICMP_TSTAMP ) {
		    $type = "ICMP_TSTAMP";
		} elsif ($icmp->{type} ==  ICMP_TSTAMPREPLY ) {
		    $type = "ICMP_TSTAMPREPLY";
		} elsif ($icmp->{type} ==  ICMP_IREQ ) {
		    $type = "ICMP_IREQ";
		} elsif ($icmp->{type} ==  ICMP_MASREQ ) {
		    $type = "ICMP_MASREQ";
		} elsif ($icmp->{type} ==  ICMP_IREQREPLY ) {
		    $type = "ICMP_IREQREPLY";
		} elsif ($icmp->{type} ==  ICMP_MASKREPLY ) {
		    $type = "ICMP_MASKREPLY";
		}
    
#		my $shost = new NetworkInfo::Discovery::Host (ipaddress => "$ip->{'src_ip'}",
#						      does_ethernet => "yes",
#								does_icmp=>"yes");
#		my $dhost = new NetworkInfo::Discovery::Host (ipaddress => "$ip->{'dest_ip'}",
#						      does_ethernet => "yes",
#								does_icmp=>"yes");
#
#		$self->add_host($shost,$dhost);
		$self->add_interface(
		    {
			ip=>$ip->{'src_ip'},
			mask=>( ($self->matches_subnet($ip->{'src_ip'})) ? $self->realmask : ""),
		    },
		    {
			ip=>$ip->{'dest_ip'},
			mask=>( ($self->matches_subnet($ip->{'dest_ip'})) ? $self->realmask : ""),
		    },
		);
	    }
    
        } else {
	    print("Unknown Ethernet Type: $ether_obj->{src_mac}:$ether_obj->{dest_mac} $ether_obj->{type}\n");
    
        }
    }
}

sub filter {
    my $self = shift;
    $self->{'filter'} = shift if (@_) ;
    return $self->{'filter'};
}
sub object {
    my $self = shift;
    $self->{'object'} = shift if (@_) ;
    return $self->{'object'};
}
sub device {
    my $self = shift;
    $self->{'device'} = shift if (@_);
    return $self->{'device'};
}
sub address {
    my $self = shift;
    $self->{'address'} = shift if (@_);
    return $self->{'address'};
}
sub netmask {
    my $self = shift;
    $self->{'netmask'} = shift if (@_);
    return $self->{'netmask'};
}
sub error {
    my $self = shift;
    $self->{'error'} = shift if (@_);
    return $self->{'error'};
}
sub snaplen {
    my $self = shift;
    $self->{'snaplen'} = shift if (@_);
    return $self->{'snaplen'};
}
sub maxcapture {
    my $self = shift;
    $self->{'maxcapture'} = shift if (@_);
    return $self->{'maxcapture'};
}
sub timeout {
    my $self = shift;
    $self->{'timeout'} = shift if (@_);
    return $self->{'timeout'};
}
sub promisc {
    my $self = shift;
    $self->{'promisc'} = shift if (@_);
    return $self->{'promisc'};
}
sub realip {
    my $self = shift;
    $self->{'realip'} = shift if (@_);
    return $self->{'realip'};
}
sub realmask {
    my $self = shift;
    $self->{'realmask'} = shift if (@_);
    return $self->{'realmask'};
}


sub matches_subnet {
    my $self= shift;
    my $ip = shift;

    my $bits;

    # get our ip in machine representation
    my $mainIP = unpack("N", pack("C4", split(/\./, $ip)));

    if ($self->realmask =~ m!^\d+\.\d+\.\d+\.\d+!) {
	my $mask_bits=unpack("B32", pack("C4", split(/\./, $self->realmask)));
	$bits=length( (split(/0/,$mask_bits,2))[0] );	
    }
    # what is left over from the mask
    $bits = 32 - ($bits || 32);

    # put this acl into machine representation
    my $otherIP = unpack("N", pack("C4", split(/\./, $self->realip)));

    # keep only the important parts of the ip address/mask pair
    my $maskedIP = $otherIP >> $bits;

    # return true if this one matches
    return 1 if  ($maskedIP == ($mainIP >> $bits));

    # return false if we didn't match any acl
    return 0;

}

sub hex2mac {
    my $data = shift;

    my ($a, $b, $c, $d, $e, $f) = ($data =~ m/^(..)(..)(..)(..)(..)(..)$/);
    return "$a:$b:$c:$d:$e:$f"; 
}

sub hex2ip {
    my $data = shift;

    my ($a, $b, $c, $d) = ($data =~ m/^(..)(..)(..)(..)$/);
    $a = hex $a;
    $b = hex $b;
    $c = hex $c;
    $d = hex $d;
    return "$a.$b.$c.$d"; 
}
1;
