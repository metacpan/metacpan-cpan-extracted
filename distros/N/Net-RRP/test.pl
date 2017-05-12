BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::RRP::Toolkit;
use Net::RRP::Request;
use Net::RRP::Response;
use Net::RRP::Codec;
use Net::RRP::Entity;
use Net::RRP::Protocol;
use Net::RRP::Server;
$loaded = 1;
print "ok 1\n";
