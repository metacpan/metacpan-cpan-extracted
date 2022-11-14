use strict;
use warnings;
use Test::More tests => 2;

use Mozilla::CA;

my $ca_file = Mozilla::CA::SSL_ca_file();
print "# $ca_file\n";
ok $ca_file, 'CA file returned';
open my $fh, '<', $ca_file
    or die "can't open $ca_file: $!";

while (<$fh>) {
    if (/--BEGIN CERTIFICATE--/) {
        ok 1, 'found a certificate';
        last;
    }
}
