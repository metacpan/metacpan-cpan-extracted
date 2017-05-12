use strict;
use warnings 'FATAL';
print "1..1\n";
eval "use Net::INET6Glue::FTP";
print $@ ? "not ok # $@\n":"ok\n"
