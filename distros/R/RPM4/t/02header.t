#!/usr/bin/perl
# $Id$

use strict;
use Test::More tests => 45;
use FindBin qw($Bin);
use RPM4;
use File::Temp;

my $headerfile;

{
my $hdr = RPM4::Header->new;
isa_ok($hdr, "RPM4::Header", "Creating empty header works");
ok(! defined($hdr->tag(1000)), "empty tag return nothings");
}

{
my $hdr = RPM4::Header->new("$Bin/test-rpm-1.0-1mdk.src.rpm");
isa_ok($hdr, "RPM4::Header", "instanciating an header from a source rpm works");
ok($hdr->hastag(1000) == 1, "Has tag 1000 (NAME), yes");
ok($hdr->hastag("NAME") == 1, "Has 'NAME', yes");
ok($hdr->hastag(1044) == 0, "Has tag 1044 (SOURCERPM), yes");
ok($hdr->listtag, "can list tag");
is($hdr->tag(1000), "test-rpm", "accessing tag by id works");
is($hdr->tag("NAME"), "test-rpm", "accessing tag by name works");
is($hdr->tag("URL"), "http://rpm4.zarb.org/", "accessing tag by name works");
is($hdr->NAME, "test-rpm", "accessing tag directly works");
ok($hdr->queryformat("%{NAME}-%{VERSION}-%{RELEASE}") eq "test-rpm-1.0-1mdk", "Queryformat is ok");
ok($hdr->nevr eq "test-rpm-1.0-1mdk", "header->nevr works");
ok(scalar($hdr->fullname) eq "test-rpm-1.0-1mdk.src", "scalar fullname works");
ok(join(",", $hdr->fullname) eq "test-rpm,1.0,1mdk,src", "wantarray fullname works");
ok($hdr->issrc == 1, "Is a src, Yes !");
ok($hdr->sourcerpmname eq "test-rpm-1.0-1mdk.src.rpm", "sourcerpmname works");
ok($hdr->removetag(1000) == 0, "Removing a tag");
ok(!defined($hdr->tag(1000)), "tag is not present");
ok($hdr->addtag(1000, 6, "new name") == 1, "Adding a tag (string type)");
ok($hdr->tag(1000) eq "new name", "Added tag return good value");
}

{
my $hdr = RPM4::Header->new("$Bin/test-rpm-1.0-1mdk.noarch.rpm");
isa_ok($hdr, "RPM4::Header", "instanciating an header from a binary rpm works");
ok($hdr->hastag(1000) == 1, "Has tag 1000 (NAME), yes");
ok($hdr->tagtype(1000) == RPM4::tagtypevalue("STRING"), "can get type of a tag");
ok($hdr->hastag(1106) == 0, "Has tag 1106 (SOURCEPACKAGE), no");
ok($hdr->listtag, "can list tag");
is($hdr->tag(1000), "test-rpm", "accessing tag by id works");
is($hdr->tag("NAME"), "test-rpm", "accessing tag by name works");
is($hdr->NAME, "test-rpm", "accessing tag directly works");
ok($hdr->queryformat("%{NAME}-%{VERSION}-%{RELEASE}") eq "test-rpm-1.0-1mdk", "Queryformat is ok");
ok(scalar($hdr->fullname) eq "test-rpm-1.0-1mdk.noarch", "scalar fullname works");
ok(join(",", $hdr->fullname) eq "test-rpm,1.0,1mdk,noarch", "wantarray fullname works");
ok($hdr->issrc == 0, "Is a src, No !");
ok($hdr->sourcerpmname eq "test-rpm-1.0-1mdk.src.rpm", "sourcerpmname works");
$headerfile = scalar($hdr->fullname) . ".hdr";


my $hdrcopy = $hdr->copy;
ok(defined $hdrcopy, "copy works");
ok($hdrcopy->tag(1000) eq 'test-rpm', "tag 1000 (NAME) from copy works");

open(my $hdfh, ">", $headerfile);
ok($hdr->write($hdfh), "Write the header works");
close($hdfh);

my $size = $hdr->hsize;
ok($size != 0, "Header size works");
ok($size == (stat($headerfile))[7], "file size is same than in memory");
}

{
open(my $hdfh, "< $headerfile");
my $hdr2 = RPM4::Header->new($hdfh);
isa_ok($hdr2, "RPM4::Header", "instanciating an header from a stream works");
close $hdfh;
unlink($headerfile);
ok($hdr2->tag(1000) eq 'test-rpm', "tag 1000 from header file works");
}

{

my $hdr = RPM4::Header->new("$Bin/test-rpm-1.0-1mdk.noarch.rpm");
foreach my $magic (0, 1) {
my $string = $hdr->string($magic);
ok($string, "can get header as string");
my $hdl = File::Temp->new(UNLINK => 1);
print $hdl $string;
seek($hdl, 0, 0);
my $hdr2 = RPM4::stream2header($hdl, $magic);
isa_ok($hdr2, "RPM4::Header", "can reparse header from a string");
}
}
