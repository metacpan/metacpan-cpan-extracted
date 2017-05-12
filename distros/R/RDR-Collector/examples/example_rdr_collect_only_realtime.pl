#!/usr/bin/perl

use strict;
use RDR::Collector;
use IO::File;

my $handle;

# This is an example wrapper script to collect/process RDR records
#
# It will receive and process the RDR in realtime.

my $rdr_client = new RDR::Collector(
			[
			ServerIP => '192.168.1.1',
			ServerPort => '33030',
			Timeout => 2,
			DataHandler => \&collect_data
			]
			);

# Setup the local RDR listener
my $status = $rdr_client->connect();

# If we could not listen tell us why.
if ( !$status )
	{
	print "Status was '".$rdr_client->return_status()."'\n";
	print "Error was '".$rdr_client->return_error()."'\n";
	exit(0);
	}

# Now just wait for RDR data.
$rdr_client->check_data_available();

exit(0);

# This routine is called from DataHandler when the module
# instance is initialised.
# 4 parameters are returned, internal ref, remote IP, remote Port and 
# the raw data
sub collect_data
{
my ( $glob ) = shift;
my ( $remote_ip ) = shift;
my ( $remote_port ) = shift;
my ( $data ) = shift;

my $attribute_line;
my $data_line;
#next unless ${$data}{'RDR_Record'}=~/^${$glob}{'RDRRecords'}/i;
my @keys = keys %{$data};
foreach my $key_name ( @keys )
        {
        $attribute_line.="$key_name,";
        $data_line.=${$data}{$key_name}.",";
        }
print "#$attribute_line\n";
print "$data_line\n";
}

