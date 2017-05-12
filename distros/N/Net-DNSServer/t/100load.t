# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test;
BEGIN { plan tests => 1; $loaded = 0}
END { ok $loaded;}

use Net::DNSServer;
use Net::DNSServer::ConfParser;
use Net::DNSServer::Base;
use Net::DNSServer::Cache;
use Net::DNSServer::DBMCache;
use Net::DNSServer::SharedCache;
use Net::DNSServer::Proxy;
use Net::DNSServer::DBI;

$loaded = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

