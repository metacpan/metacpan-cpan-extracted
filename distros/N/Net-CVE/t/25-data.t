#!/usr/bin/perl

use 5.014002;
use warnings;

use Test::More;
use Test::Warnings;

use Net::CVE;

my $jf = "Files/CVE-2022-26928.json";

sub chk_data {
    my ($msg, $r) = @_;
    ok ($r,				"$msg Has value");
    is (ref $r,		"HASH",		"$msg Data type");
    is ($r->{dataType},	"CVE_RECORD",	"$msg Content");
    } # chk_data

ok (my $cr = Net::CVE->new,		"New reporter");
ok ($cr->get ($jf),			"Read stored report");
chk_data ("new/get/data",	$cr->data);

chk_data ("get/data", Net::CVE->get ($jf)->data);
chk_data ("data",     Net::CVE->data ($jf));

done_testing;
