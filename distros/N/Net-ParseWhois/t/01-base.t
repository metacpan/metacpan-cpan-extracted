#
# TODO: more/better/real tests.
#
# (is it ok to have make test cause a network operation .. ?)
#

BEGIN { $| = 1; print "1..2\n"; }
END { print "not ok 1\n" unless $loaded;}

use Net::ParseWhois;

$loaded = 1;
print "ok 1\n";

$reg = new Net::ParseWhois::Domain::Registrar;
print "not " unless defined($reg);
print "ok 2\n";

