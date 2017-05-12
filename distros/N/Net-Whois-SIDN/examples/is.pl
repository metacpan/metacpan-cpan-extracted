#!/usr/bin/env perl
# see is-output.txt for an example of this output

use Net::Whois::SIDN;
use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;

@ARGV==1 || @ARGV==2
   or die "Usage: $0 <domain> [<language>]\n";

my ($domain, $lang) = @ARGV;

my $w = Net::Whois::SIDN->new(drs_version => '5.0', trace => 1);

my ($rc, $d) =  $w->is($domain, lang => ($lang || 'NL'));
$rc==0 or die $d;

print "\n--> Perl structure\n";
print Dumper $d;
