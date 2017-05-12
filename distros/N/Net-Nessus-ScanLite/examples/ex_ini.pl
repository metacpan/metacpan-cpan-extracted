#!/usr/local/bin/perl -Tw

use strict;
use warnings;
use lib qw( ../lib );
use Net::Nessus::ScanLite;


my $example = "example.ini";
my $addr = "10.0.0.1";

printf("Testing ini file path to $example\n");
my $nessus = Net::Nessus::ScanLite->new( Cfg => $example );
die($nessus->error . "\n") if( $nessus->code );

## $nessus->ssl(0);   # Uncomment if nessusd not using ssl
scan($nessus,$addr);

print "Testing ini object from $example\n";
my $ex = Config::IniFiles->new( -file => $example);
die("Can't open $example $!\n") unless($ex);

$nessus = Net::Nessus::ScanLite->new( Cfg => $ex );
## $nessus->ssl(0);   # Uncomment if nessusd not using ssl
scan($nessus,$addr);





die("Done\n");

sub scan
	{
	my ($nessus,$addr) = @_;
  	if( $nessus->login() )
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
