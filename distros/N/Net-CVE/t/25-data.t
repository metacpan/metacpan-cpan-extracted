#!/usr/bin/perl

use 5.014002;
use warnings;

use Test::More;
use Test::Warnings;

use Net::CVE;

my $jf = "Files/CVE-2022-26928.json";

# https://www.cpantesters.org/cpan/report/4ec2920e-7174-11ee-98b0-b3c3213a625c
# #   Failed test 'Data direct'
# #   at t/30-get.t line 32.
# #     Structures begin differing at:
# #          $got->{containers} = Does not exist
# #     $expected->{containers} = HASH(0x7f86ff8f1888)
# # Looks like you failed 1 test of 16.
# t/30-get.t ...... 
# Dubious, test returned 1 (wstat 256, 0x100)
# Failed 1/16 subtests 

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
