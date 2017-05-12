#!/usr/bin/perl
# It will get the policy (first or by name), create new policy with 
# nmap file and start the scan

use strict;
use Net::Nessus::XMLRPC;

my $hostfile=shift;
my $nmapfile=shift;

# '' is same as https://localhost:8834/
my $n = Net::Nessus::XMLRPC->new ('','user','pass');

die "URL, user or passwd not correct: ".$n->nurl."\n" unless ($n->logged_in);

print "Logged in!\n";

my $tp=$n->policy_get_first();
# or if you want specific policy which you made for nmap called "nmap":
# my $tp=$n->policy_get_id('nmap');
print "Using template policy: ".$tp."\n";

my $polid=$n->policy_copy($tp);
print "Using policy ID: $polid ";
my $polname=$n->policy_get_name($polid);
print "with name: $polname\n";

my $nmapufile = $n->file_upload($nmapfile);
my $nopt = {
'policy_name' => "nmap-$nmapufile"
};

$nopt->{'Nmap (NASL wrapper)[file]:File containing grepable results :'} => $nmapufile;
# or for XML:
# $nopt->{'Nmap (XML file importer)[file]:File containing XML results :'}='nmap7.xml';
$n->policy_set_opts($polid,$nopt);

my $scanid=$n->scan_new_file($polid,"nmap-$nmapfile",'',$hostfile);

print "Started scan with ID: $scanid\n";

