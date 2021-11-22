use Test::More tests => 1; 
use Net::RFC3161::Timestamp;


my $t=list_tsas();

is $t->{"dfn.de"}, "http://zeitstempel.dfn.de", "Found DFN in TSA list";

