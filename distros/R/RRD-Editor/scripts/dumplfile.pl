#!/usr/bin/perl -w

#
# dump out the binary header of an RRD file in human readable format
#
# usage: test.pl <myfile.rrd>
#
#

open my $fd, "<", $ARGV[0];
binmode $fd;
read $fd,my $head, 256; # dump out first 256 bytes of header only
for (my $i=0; $i<length($head); $i++) {
if (substr($head,$i,1) =~ m/[a-zA-Z]/) {
   # a-z, A-Z character
   print substr($head,$i,1)," ";
} else { 
   # unprintable, just show hex
   printf "%x ",ord(substr($head,$i,1));
}
}

