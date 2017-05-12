# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# 1:  Check that we're installed.

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use PGP::FindKey;
$loaded = 1;
print "ok 1\n";

print "If you need to use a proxy, make sure the http_proxy variable is set.\n\n";

$obj = new PGP::FindKey
	('keyserver' => 'keyserver.pgp.com',
	 'address'   => 'prz@mit.edu');

if (defined($obj)) { print "Key search successful; name: ".$obj->name.", keyid: ".$obj->result."\n"; }
else { warn "Key search FAILED.\n"; }
