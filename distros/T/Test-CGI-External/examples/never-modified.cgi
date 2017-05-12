#!/home/ben/software/install/bin/perl
use warnings;
use strict;
my $lm = $ENV{HTTP_IF_MODIFIED_SINCE};
if ($lm) {
    print "Status: 304\n\n";
}
else {
    print <<EOF;
Content-Type: tura/satana
Last-Modified: Thu, 1 Jan 1970 00:00:00 GMT

You won't find it down there, Columbus.
EOF
}
