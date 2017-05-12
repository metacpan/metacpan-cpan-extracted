#!/usr/bin/perl

use strict;
use RDR::Processor;
use IO::File;

# This is an example wrapper script to process RDR records
# You should specify two elements when running the script
#
# the RDR raw data file and the RDR name.
#

my $handler_file;

my $filename = $ARGV[0];
my $RDR_Type = $ARGV[1];

my $rdr_client = new RDR::Processor(
			[
			Filename => $filename,
			RDRRecords => $RDR_Type,
			DataHandler => \&display_data
			]
			);

$rdr_client->process_file();

exit(0);

# This routine is called from DataHandler when the module
# instance is initialised.
# 4 parameters are returned, internal ref, remote IP, remote Port and 
# a pointer to a hash with key/value pairs of the RDR record.
# When called with Processor remote_ip and remote_port contain localhost
sub display_data
{
my ( $glob ) = shift;
my ( $remote_ip ) = shift;
my ( $remote_port ) = shift;
my ( $data ) = shift;

my $attribute_line;
my $data_line;

# Comment out this line to show all RDRs.
next unless ${$data}{'RDR_Record'}=~/^${$glob}{'RDRRecords'}/i;


my @keys = keys %{$data};
foreach my $key_name ( @keys )
	{
	$attribute_line.="$key_name,";
	$data_line.=${$data}{$key_name}.",";
	}
print "#$attribute_line\n";
print "$data_line\n";
}

