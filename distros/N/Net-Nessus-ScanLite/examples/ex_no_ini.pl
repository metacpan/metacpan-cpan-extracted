#!/usr/local/bin/perl -Tw

use strict;
use warnings;
use lib qw( ../lib );
use Net::Nessus::ScanLite;


my $example = "example.ini";
my $addr = "10.0.0.1";
my $user = 'netreg';
my $pwd = '********';
my $nessus_host = "nessusd.host.net";
my $nessus = Net::Nessus::ScanLite->new(
                                host            => $nessus_host,
                                port            => 1241,
                                ssl             => 1,  # set to 0 if nessusd is not running ssl
				preferences	=> {
						host_expansion 		=> 'none',
						safe_checks 		=> 'yes',
						checks_read_timeout 	=> 1,
						plugin_set		=> "10835;10861;11808;11921;11790",
						},
                                );

scan($nessus,$addr,$user,$pwd);
print "Testing method configuration. Hit Enter.";
<STDIN>;
$nessus = Net::Nessus::ScanLite->new();
$nessus->host($nessus_host);
$nessus->user($user);
$nessus->password($pwd);
# $nessus->ssl(0); # Uncomment if nessusd is not running ssl
$nessus->preferences( { host_expansion => 'none', safe_checks => 'yes', checks_read_timeout => 1 });
$nessus->plugin_set("10835;10861;11808;11921;11790");

scan($nessus,$addr,$user,$pwd);






die("Done\n");

sub scan
	{
	my ($nessus,$addr,$user,$pwd) = @_;
  	if( $nessus->login($user,$pwd) )
        	{
		printf("Connected to %s\n",$nessus->hostport);
        	$nessus->attack($addr);
		printf("Plugin list [%s]\n",$nessus->plugin_set);
		printf("Attack took %d seconds.\n",$nessus->duration);
        	printf("Total info's = %d\n",$nessus->total_info);
        	foreach( $nessus->info_list )
                	{
                	my $info = $_;
                	printf("\n\nID: %s\n  Port: %s\n  Dessc: %s\n",
                        	$info->ScanID,
                        	$info->Port,
                        	$info->Description);
                	}
        	printf("Total hole's = %d\n",$nessus->total_holes);
        	foreach( $nessus->hole_list )
                	{
                	my $hole = $_;
                	printf("\n\nID: %s\n  Port: %s\n  Dessc: %s\n",
                        	$hole->ScanID,
                        	$hole->Port,
                        	$hole->Description);
                	}

        	}
   	else
        	{
        	die(sprintf("Nessus login failed %d: %s\n",$nessus->code,$nessus->error));
        	}

	}
