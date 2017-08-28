package Simple::Confvpn;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(vpn_status vpn_start vpn_stop route_configuration);

our $VERSION = '1.09';


sub vpn_status
{
#----------------------------------------------------------------------
# Function: To check vpn status
#----------------------------------------------------------------------
	my $ppp_result=`ifconfig | grep ppp.`;
	if($? != 0)
	{
		print "please check the ifconfig command";
		exit 1;
	}
	else
	{
		if(length($ppp_result)>0)
		{
  			my @lines = split /\n/, $ppp_result;
  			foreach my $line (@lines)
  			{
    				my $ppp=substr($line,0,4);
    				my $ppp_inet=`ifconfig $ppp | grep -e "inet adr" -e"inet addr"`;
				if($? != 0)
				{
					print "please check the ifconfig command";
					exit 1;
				}
				else
				{	
    					if(length($ppp_inet)>0)
    					{
						print "virtual private network[VPN] connection is running..";
						return 0;
    					}
				}
  			}	

		 }	
	}
}


sub vpn_start
{
#----------------------------------------------------------------------
# Function: To start the vpn
#----------------------------------------------------------------------
		my $csa=system("pppd call pure-ru1");
		die "pppd rule call is failing.." if($csa!=0);  		
		my $cpt=0;
		my $timeOut=30; #default
  		while(length(`ifconfig ppp0 | grep -e "inet adr" -e"inet addr"`)<=0 && $cpt<$timeOut)
  		{
    			$cpt++;
    			print "Waited $cpt/$timeOut sec for the vpn to set up...";
    			sleep 1;
  		}
  		if($cpt<$timeOut)
  		{
    			print "Started the service..";
			return 0;
  		}
  		else
  		{
    			print "A vpn connection was not set after $timeOut sec.";
			return 1;
  		}
}



sub route_configuration
{
#-----------------------------------------
##cpt route 0 for destination
##cpt route 1 for gateway
##cpt route 7 for interface
#------------------------------------------
	my $cptRoute=shift;
  	my $csa =system("route add default dev ppp0");
	die "adding route command is failing.." if($csa!=0); 
  	my $route_result=`route -n`;
	if($route_result ne 0)
	{
		print "please check 'route -n' command after adding the default route";
		exit 1;
	}
	else
	{	
  		my @linesRoute = split /\n/, $route_result;
  		foreach my $lineRoute (@linesRoute)
  		{
    			my @dataRoute = split / /, $lineRoute;
    			my $destination="";    
    			my $gateway="";        
    			my $interface="";      
    			foreach my $dataRoute (@dataRoute)
    			{
      				if(length($dataRoute)>0)
      				{
        				if($cptRoute==0) {$destination=$dataRoute;}
        				if($cptRoute==1) {$gateway=$dataRoute;}
        				if($cptRoute==7) {$interface=$dataRoute;}
        				$cptRoute++;
      				}
    			}
    			if($destination eq '0.0.0.0' && index($interface, 'ppp') == -1)
    			{
      				my $csg=system("route del -net $destination gw $gateway");
				die "deleting route command is failing.." if($csg!=0);
    			}
    			$cptRoute=0;
  		}
		print "route configuration is done..";  
		return 0;
	}
}


sub vpn_stop
{
#----------------------------------------------------------------------
# Function: To stop vpn 
#----------------------------------------------------------------------
  	`ps -ef | grep ppp | awk '{print $2}' | xargs kill`; 
	if($? ne 0)
	{
		print "couldnot stop the Vpn service..";
		exit 1;
	}
	else
	{	
		print "service vpn stopped";
		return 0;
	}
}


1;

__END__

=head1 NAME

Simple::Confvpn - Simple Perl extension for [configuring/stopping/starting] the vpn service in linux server.

=head1 SYNOPSIS

    use Simple::Confvpn;
    my $stat = vpn_status(); 

    use Simple::Confvpn;
    my $stat = vpn_start();

    use Simple::Confvpn;
    my $stat = route_configuration(0);

    use Simple::Confvpn;
    my $stat = vpn_stop();

=head1 DESCRIPTION

Simple::Confvpn utility or module is very usefull for configuring/stop/start/status of the vpn using pppd in linux,
and using this approach, able to find the fastest solutions of the functionalities for vpn configuration.

=head1 AUTHOR

K.Kaavannan, <kaavannaniisc@gmail.com>


=head1 BUGS
 
Here, <<kaavannanwayis@solution4u.com>>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by kaavannan Karuppaiyah

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.

=cut 
                                                                                        132,1         Bot
