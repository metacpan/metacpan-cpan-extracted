#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";    # the module next to this script, whatever the current directory
use Net::IPData;

my $api_key = $ENV{IPDATA_API_KEY} or die "Set IPDATA_API_KEY environment variable\n";

my $ipdata = Net::IPData->new(api_key => $api_key);

# Look up a specific IP
my $result = $ipdata->lookup('8.8.8.8');
printf "IP:        %s\n", $result->{ip};
printf "City:      %s\n", $result->{city};
printf "Region:    %s\n", $result->{region};
printf "Country:   %s (%s)\n", $result->{country_name}, $result->{country_code};
printf "Continent: %s\n", $result->{continent_name};
printf "Coords:    %.4f, %.4f\n", $result->{latitude}, $result->{longitude};
printf "ASN:       %s (%s)\n", $result->{asn}{asn}, $result->{asn}{name};
printf "Timezone:  %s\n", $result->{time_zone}{name};
printf "Currency:  %s (%s)\n", $result->{currency}{name}, $result->{currency}{code};
printf "EU:        %s\n", $result->{is_eu} ? 'Yes' : 'No';
printf "Threat:    %s\n", $result->{threat}{is_threat} ? 'Yes' : 'No';
printf "Satellite: %s\n", $result->{is_satellite} ? 'Yes' : 'No';   # key present only when true
printf "Anycast:   %s\n", $result->{is_anycast} ? 'Yes' : 'No';     # key present only when true

print "\n--- Bulk lookup ---\n";
my $bulk = $ipdata->bulk(['8.8.8.8', '1.1.1.1', '9.9.9.9']);
for my $r (@$bulk) {
    printf "%s -> %s, %s\n", $r->{ip}, $r->{city} // 'N/A', $r->{country_name};
}

print "\n--- Field filtering ---\n";
my $partial = $ipdata->lookup('1.1.1.1', fields => [qw(ip country_name asn)]);
printf "IP: %s, Country: %s, ASN: %s\n",
    $partial->{ip}, $partial->{country_name}, $partial->{asn}{name};

print "\n--- Single field ---\n";
printf "Country: %s\n", $ipdata->country_name('1.1.1.1');
