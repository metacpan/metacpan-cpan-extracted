#!perl

use strict;
use warnings;

use Net::Whois::ARIN;

my $whois = Net::Whois::ARIN->new;

my @org = $whois->organization("WSU");

printf "found " . scalar @org . " organization(s) matching %s\n",
    $org[0]->OrgID;

printf "The organization %s is located at:\n", $org[0]->OrgName;

printf "%s\n", $org[0]->Address;

printf "%s, %s  %s\n", 
    $org[0]->City, 
    $org[0]->StateProv, 
    $org[0]->PostalCode;

printf "The organization information for %s was created %s and updated %s.\n",
    $org[0]->OrgID,
    $org[0]->RegDate,
    $org[0]->Updated;

my @contacts = $org[0]->contacts();
printf "There are %d registered contacts for %s.\n",
    scalar @contacts,
    $org[0]->OrgID;

exit;

__END__

OrgName:    Washington State University
OrgID:      WSU
Address:    Intercollegiate Center for Nursing Education
Address:     West 2917 Fort George Wright Drive
City:       Spokane
StateProv:  WA
PostalCode: 99204-5277
Country:    US
Comment:
RegDate:    1992-01-14
Updated:    1992-01-16
