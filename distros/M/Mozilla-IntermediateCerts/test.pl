#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Data::Dumper;

use lib 'lib';

use Mozilla::IntermediateCerts;

my $certs = Mozilla::IntermediateCerts->new( 
				moz_int_cert_path => 'http://test.simperl.com/PublicAllIntermediateCertsWithPEMReport_10.csv' 
				#moz_int_cert_path => 'http://test.simperl.com/PublicAllIntermediateCertsWithPEMReport_full.csv' 
);



#warn Dumper( $certs );
for my $cert ( @{ $certs->certs } )
{
	#print $cert->{'Certificate Serial Number'} . "\n";
	print $cert->ca_owner . "\n";
	print $cert->certificate_serial_number . "\n";
	print $cert->pem_info;
}
exit;
binmode STDOUT, ":utf8";
my $cert_dir =  '/tmp/cert_dir';
mkdir $cert_dir;

for my $cert ( $certs->certs  )
{
	#print $cert->{'Parent Name'} . ' ' . $cert->{'Certificate Name'} . "\n";
	my $file =  $cert->{'Parent Name'} . '-' . $cert->{'Certificate Subject Common Name'} . '-' . $cert->{'Certificate Serial Number'};
	$file =~ s/\W/_/g;
	open my $fh, '>', "$cert_dir/$file" or die $!;
	print $fh $cert->{'PEM Info'};
}
