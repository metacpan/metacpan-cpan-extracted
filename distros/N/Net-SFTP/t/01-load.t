# $Id: 01-load.t,v 1.3 2003/12/03 15:39:44 autarch Exp $

my $loaded;
BEGIN { print "1..1\n" }
use Net::SFTP;
$loaded++;
print "ok 1\n";
END { print "not ok 1\n" unless $loaded }
