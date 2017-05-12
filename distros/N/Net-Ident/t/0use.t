# $Id: 0use.t,v 1.2 1999/03/08 23:27:19 john Exp $
BEGIN { $| = 1; print "1..1\n"; }
END { print "not ok 1\n" unless $loaded; }
use Net::Ident qw(:fh :apache);
$loaded = 1;
print "ok 1\n";
