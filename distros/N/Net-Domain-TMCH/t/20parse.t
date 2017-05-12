#!/usr/bin/env perl
# Create an template
use warnings;
use strict;

use lib 'lib', '../WSSSIG/lib', '../XMLWSS/lib';
use Test::More tests => 14;

my $testset  = 'test/testset-20130715';

# copy of "$testset/smd-active/Court-Holder-English-Active.smd", distributed
# with the other files.
my $testfile = "t/20ok.smd";

use Net::Domain::SMD::Schema ();

my $smd = Net::Domain::SMD::Schema->new;
 
ok(defined $smd, 'instantiate smd object');
isa_ok($smd, 'Net::Domain::SMD::Schema');

my $info = $smd->read($testfile);
ok(defined $info, "parsed testfile $testfile");
isa_ok($info, 'Net::Domain::SMD::File');

is($info->filename, $testfile);
my @marks = $info->marks;
cmp_ok(scalar @marks, '==', 1, 'one mark');
is($marks[0], 'Test & Validate');

is($info->smdID, '0000001711373633628408-65535');
eq_array([$info->labels], 
  [ qw/test---validate test--validate test-and-validate test-andvalidate
       test-validate testand-validate testandvalidate testvalidate/ ] );
is($info->from,  '2013-07-12T12:53:48.408Z', 'from date');
is($info->fromTime,  '1373633628.408', 'from timestamp');
is($info->until, '2017-07-09T22:00:00.000Z', 'until');
is($info->untilTime, '1499637600', 'until timestamp');

my $payload = $info->payload;
ok(defined $payload, 'got payload');
isa_ok($payload, 'XML::LibXML::Element');
#warn $payload->toString(1);

use Data::Dumper;
$Data::Dumper::Indent=1;
#warn Dumper $info->_mark;
#warn Dumper [$info->courts];
