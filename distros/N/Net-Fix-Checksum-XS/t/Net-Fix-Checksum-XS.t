# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Net-Fix-Checksum-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 26;
BEGIN { use_ok('Net::Fix::Checksum::XS') };

# Sample fix message to start off
my $fixmsg = "8=FIX.4.4|9=122|35=D|34=215|49=CLIENT12|52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|";
# Use SOH separator - from now on all separators will be written "\001"
$fixmsg =~ s/\|/\001/g;

my $fixnocksum = $fixmsg =~ s/10=\d{3}\001$//r;
my $fixbadcksum1 = $fixmsg =~ s/10=\d{3}\001$/10=123\001/r;
my $fixbadcksum2 = $fixmsg =~ s/49=CLIENT12/49=CLIENT13/r; # checksum will be +1

my $verylongstring = "@" x 4096; # This string can be added without affecting the checksum as (sum % 256) == 0
my $fixtoolong = $fixnocksum =~ s/49=CLIENT12/49=CLIENT21$verylongstring/r;
my $fixlongbadcksum = $fixtoolong . "10=123\001";
my $fixlonggoodcksum = $fixtoolong . "10=072\001";

my $fixinvalidcksum = $fixmsg =~ s/10=\d{3}\001$/10=256\001/r; # 256 is the max checksum value
my $fixbadterminaison = $fixnocksum =~ s/\001$//r;
my $fixbadtermchsum = $fixmsg =~ s/\001$//r;

ok(Net::Fix::Checksum::XS::validate_checksum($fixmsg) eq 1, "Validate Checksum OK");
ok(Net::Fix::Checksum::XS::generate_checksum($fixnocksum) eq "072", "Generate Checksum OK");
ok(Net::Fix::Checksum::XS::generate_checksum($fixmsg) eq "072", "Generate Checksum ignores existing cksum");
ok(Net::Fix::Checksum::XS::generate_checksum($fixbadcksum1) eq "072", "Generate ignores existing bad cksum 1");
ok(Net::Fix::Checksum::XS::generate_checksum($fixbadcksum2) eq "073", "Generate ignores existing bad cksum 2");
ok(Net::Fix::Checksum::XS::replace_checksum($fixmsg) eq $fixmsg, "Replaced checksum matches");
ok(Net::Fix::Checksum::XS::replace_checksum($fixnocksum) eq $fixmsg, "Added checksum matches");

ok(Net::Fix::Checksum::XS::validate_checksum($fixbadcksum1) eq 0, "Bad checksum 1 is invalid");
ok(Net::Fix::Checksum::XS::validate_checksum(Net::Fix::Checksum::XS::replace_checksum($fixbadcksum1)) eq 1, "Bad checksum 1 corrected OK");
ok(Net::Fix::Checksum::XS::validate_checksum($fixbadcksum2) eq 0, "Bad checksum 2 is invalid");
ok(Net::Fix::Checksum::XS::validate_checksum(Net::Fix::Checksum::XS::replace_checksum($fixbadcksum2)) eq 1, "Bad checksum 2 corrected OK");

is(Net::Fix::Checksum::XS::replace_checksum($fixtoolong), undef, "Too long string returns undef");
is(Net::Fix::Checksum::XS::validate_checksum($fixnocksum), undef, "Validate with no checksum returns undef");
ok(Net::Fix::Checksum::XS::validate_checksum($fixlongbadcksum) eq 0, "Validate on long strings, bad cksum variant");
ok(Net::Fix::Checksum::XS::validate_checksum($fixlonggoodcksum) eq 1, "Validate works on long strings, good cksum variant");
ok(Net::Fix::Checksum::XS::generate_checksum($fixtoolong) eq "072", "Generate works on long strings");
ok(Net::Fix::Checksum::XS::generate_checksum($fixlongbadcksum) eq "072", "Generate on long strings, bad cksum variant");
ok(Net::Fix::Checksum::XS::generate_checksum($fixlonggoodcksum) eq "072", "Generate on long strings, good cksum variant");

is(Net::Fix::Checksum::XS::validate_checksum($fixinvalidcksum), undef, "Checksum cannot be 256 and up");
is(Net::Fix::Checksum::XS::generate_checksum($fixbadterminaison), undef, "Generate fails on madly terminated messages");
is(Net::Fix::Checksum::XS::replace_checksum($fixbadterminaison), undef, "Replace fails on madly terminated messages");
is(Net::Fix::Checksum::XS::validate_checksum($fixbadterminaison), undef, "Validate fails on madly terminated messages");
is(Net::Fix::Checksum::XS::generate_checksum($fixbadtermchsum), undef, "Generate fails on madly terminated messages, cksum variant");
is(Net::Fix::Checksum::XS::replace_checksum($fixbadtermchsum), undef, "Replace fails on madly terminated messages, cksum variant");
is(Net::Fix::Checksum::XS::validate_checksum($fixbadtermchsum), undef, "Validate fails on madly terminated messages, cksum variant");

