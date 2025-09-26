BEGIN { $| = 1; print "1..1\n" }

use NetBox::API;

if ($NetBox::API::VERSION < 0.0001) {
   print STDERR <<EOF;

***
*** WARNING
***
*** old version of NetBox::API still installed,
*** your perl library is corrupted.
***
*** please manually uninstall older NetBox::API versions
*** or use "make install UNINST=1" to remove them.
***

EOF
}

print "ok 1\n";
