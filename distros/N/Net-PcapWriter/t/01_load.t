use strict;
use warnings;

print "1..1\n";
eval "use Net::PcapWriter";
print $@ ? "not ok # $@\n": "ok\n";

