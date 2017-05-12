use strict;
use warnings;
use Text::CSV;
use Net::Netmask;

$|=1;

my $csv = Text::CSV->new();
my %data;

while (<>) {
  chomp;
  next if m!^Prefix!;
  next unless $csv->parse($_);
  my ($prefix,$designation,$date,$whois,$status,$note) = $csv->fields();
  next unless $whois;
  my $blk = Net::Netmask->new2($prefix) or die "$!\n";
  $data{ $blk->desc() } = $whois;
}

use Data::Dumper;
local $Data::Dumper::Indent=1;
print Dumper( \%data );
