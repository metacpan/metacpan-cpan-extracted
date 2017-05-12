#!/usr/bin/perl
use strict;
use RPM4;
use RPM4::Header;
use RPM::Header::PurePerl;

my $rpmfile = shift or die("perl dump_rpm.pl rpmfile.rpm");
my $rpm4 = RPM4::Header->new($rpmfile);
foreach my $tag ($rpm4->listtag) {
    print "$tag:".$rpm4->tagtype($tag).":".RPM4::tagName($tag);
    print ":".$rpm4->tag($tag)."\n";
    print "\n";
}

tie my %rpmhdr, "RPM::Header::PurePerl", $rpmfile 
    or die "Problem, could not open $rpmfile";

foreach my $tag (keys %rpmhdr) {
    print "$tag:$rpmhdr{$tag}\n";
}
