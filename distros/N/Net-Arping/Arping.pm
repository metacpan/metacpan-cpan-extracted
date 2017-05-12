#                                                                               
# Arping.pm
#                                                                               
# Copyright (c) 2002 Oleg Prokopyev. All rights reserved. This program is      
# free software; you can redistribute it and/or modify it under the same       
# terms as Perl itself.                                                         
#                                                                               
# Comments/suggestions to riiki@gu.net                                       
#                                                                               

package Net::Arping;

use strict;

require Exporter;
require DynaLoader;

use Carp;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $default_timeout);

$VERSION = '0.02'; 

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(&arping);
@EXPORT_OK=qw(&send_arp);

bootstrap Net::Arping $VERSION;

$default_timeout=1; # default timeout is 1 second

#  some comment
#  default_interface - using libnet_select_device function	

sub usage {
	croak("Usage:\n \t \$q->arpping(\$host) \n or \n \t \$q->arping(Host => \$host [, Interface => \$interface, Timeout =>\$sec])");
}

sub new {                                                                       
        my $class=shift;                                                        
        my $self={ };                                                           
        return bless $self,$class;                                              
}

sub arping {

	my($self)=@_;

	my(
		$host,
		$interface,
		$timeout,
		$result
	);
	
	if(@_ == 1) {usage();}
	
	$timeout=$default_timeout;

	if(@_ == 2) { #we have only host

	    $host=$_[1];
	    $result=send_arp($host,$timeout);

	} else {
		my %args;
		(undef,%args)=@_;
		
		$interface=""; 
		$host="";
		
		foreach(keys %args) {
			if(/^Interface$/) {

				$interface=$args{Interface};

				# just a little test
				if($interface=~ m/^(\s*)$/) {
					croak("hmm... strange interface\n");
				}

			} elsif (/^Timeout$/) {
				$timeout=$args{Timeout};
				
				#one more little test
				if((!($timeout=~ m/^(\d+)$/))||($timeout==0)) {
					croak("hmm... strange timeout\n");;
				}

			  } elsif (/^Host$/) {
				$host=$args{Host};
			    } else {
				usage();
			      }		
		}

		if(!($host=~ m/^([A-Za-z0-9-.]+)$/)) {
			# just a little test - not very good of course - but ...
			croak("hmm... strange host\n");
		}
		if($interface ne "") {	
			$result=send_arp($host,$timeout,$interface);
		} else {
			$result=send_arp($host,$timeout);
		  }	
	}

#	print "test:Host=$host,Interface=$interface,Timeout=$timeout\n";
#	print $result,"\n";    

	return $result;	
}
1;
__END__

=head1 NAME

Net::Arping - Ping remote host by ARP packets 

=head1 SYNOPSIS

  use Net::Arping;
  
  $q=Net::Arping->new();
  $result=$q->arping($host);

  if($result eq "0") {
        print "Sorry , but $host is dead...\n";
  } else {
        print "wow... it is alive... Host MAC address is $result\n";
  }

  You can also specify source interface and timeout. Default timeout
is 1 second.

  $result=$q->arping(Host => $host,Interface => "eth0",Timeout => "4");	
  if($result eq "0") {
	print "Sorry, but $host is dead on device eth0...\n";
  } else {
	print "wow... it is alive... Host MAC address is $result\n";
  }
	  

=head1 DESCRIPTION

The module contains function for testing remote host reachability
by sending ARP packets.  

The program must be run as root or be setuid 
to root. 

For compiling the module you need libnet library 
(http://www.packetfactory.net/libnet/dist/libnet.tar.gz) 
and pcap library 
(http://www.tcpdump.org/daily/libpcap-current.tar.gz). 

=head1 FUNCTIONS

=over 2

=item Net::Arping->new();

Create a new arping object.

=item $q->arping($host); $q->arping(Host => $host [, Interface => $interface, Timeout => $sec]); 

Arping the remote host. Interface and Timeout parameters are optional.
Default timeout is 1 second. Default device is selected
by libnet_select_device function. 

=back

=head1 COPYRIGHT                                                                
                                                                                
Copyright (c) 2002 Oleg Prokopyev. All rights reserved. It's a free software. 
You can redistribute it and/or modify it under the same terms as Perl 
itself.

=head1 SEE ALSO

pcap(3), libnet(3)

=head1 AUTHOR

Oleg Prokopyev, E<lt>riiki@gu.netE<gt>

=cut
