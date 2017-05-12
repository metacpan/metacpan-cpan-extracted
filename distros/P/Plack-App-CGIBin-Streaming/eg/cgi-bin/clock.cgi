#!/usr/bin/perl

use strict;
use warnings;

my $times=do {no warnings 'numeric'; 0+$ENV{QUERY_STRING}};
$times=1 if $times<1;
$times=100 if $times>100;

$|=0;

my $boundary='The Final Frontier';
print <<"EOF";
Status: 200
Content-Type: multipart/x-mixed-replace;boundary="$boundary";

EOF

$boundary="--$boundary\n";

my $mpheader=<<'HEADER';
Content-type: text/html; charset=UTF-8;

HEADER

for(1..$times) {
    print ($boundary, $mpheader,
           '<html><body><h1>'.localtime()."</h1></body></html>\n");
    $|=1; $|=0;
    sleep 1;
}

print ($boundary);
