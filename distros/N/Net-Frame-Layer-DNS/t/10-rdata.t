use Test;
BEGIN { plan(tests => 20) }

use strict;
use warnings;

use Net::Frame::Layer::DNS qw(:consts);
use Net::Frame::Layer::DNS::Question qw(:consts);
use Net::Frame::Layer::DNS::RR qw(:consts);
use Net::Frame::Layer::DNS::RR::A;
use Net::Frame::Layer::DNS::RR::AAAA;
use Net::Frame::Layer::DNS::RR::CNAME;
use Net::Frame::Layer::DNS::RR::HINFO;
use Net::Frame::Layer::DNS::RR::MX;
use Net::Frame::Layer::DNS::RR::NS;
use Net::Frame::Layer::DNS::RR::PTR;
use Net::Frame::Layer::DNS::RR::rdata;
use Net::Frame::Layer::DNS::RR::SOA;
use Net::Frame::Layer::DNS::RR::SRV;
use Net::Frame::Layer::DNS::RR::TXT;

my ($rdata, $expectedOutput);

# A
$rdata = Net::Frame::Layer::DNS::RR::A->new;
$expectedOutput = 'DNS::RR::A: address:127.0.0.1';
print $rdata->print . "\n";
ok($rdata->print, $expectedOutput);

$expectedOutput = '7f000001';
print unpack "H*", $rdata->pack;
print "\n";
ok((unpack "H*", $rdata->pack), $expectedOutput);

# AAAA
$rdata  = Net::Frame::Layer::DNS::RR::AAAA->new;
$expectedOutput = 'DNS::RR::AAAA: address:::1';
print $rdata->print . "\n";
ok($rdata->print, $expectedOutput);

$expectedOutput = '00000000000000000000000000000001';
print unpack "H*", $rdata->pack;
print "\n";
ok((unpack "H*", $rdata->pack), $expectedOutput);

# CNAME
$rdata = Net::Frame::Layer::DNS::RR::CNAME->new;
$expectedOutput = 'DNS::RR::CNAME: cname:localhost';
print $rdata->print . "\n";
ok($rdata->print, $expectedOutput);

$expectedOutput = '096c6f63616c686f737400';
print unpack "H*", $rdata->pack;
print "\n";
ok((unpack "H*", $rdata->pack), $expectedOutput);

# HINFO
$rdata = Net::Frame::Layer::DNS::RR::HINFO->new;
$expectedOutput = 'DNS::RR::HINFO: cpu:PC  os:Windows';
print $rdata->print . "\n";
ok($rdata->print, $expectedOutput);

$expectedOutput = '0250430757696e646f7773';
print unpack "H*", $rdata->pack;
print "\n";
ok((unpack "H*", $rdata->pack), $expectedOutput);

# MX
$rdata = Net::Frame::Layer::DNS::RR::MX->new;
$expectedOutput = 'DNS::RR::MX: preference:1
DNS::RR::MX: exchange:localhost';
print $rdata->print . "\n";
ok($rdata->print, $expectedOutput);

$expectedOutput = '0001096c6f63616c686f737400';
print unpack "H*", $rdata->pack;
print "\n";
ok((unpack "H*", $rdata->pack), $expectedOutput);

# NS
$rdata = Net::Frame::Layer::DNS::RR::NS->new;
$expectedOutput = 'DNS::RR::NS: nsdname:localhost';
print $rdata->print . "\n";
ok($rdata->print, $expectedOutput);

$expectedOutput = '096c6f63616c686f737400';
print unpack "H*", $rdata->pack;
print "\n";
ok((unpack "H*", $rdata->pack), $expectedOutput);

# PTR
$rdata = Net::Frame::Layer::DNS::RR::PTR->new;
$expectedOutput = 'DNS::RR::PTR: ptrdname:localhost';
print $rdata->print . "\n";
ok($rdata->print, $expectedOutput);

$expectedOutput = '096c6f63616c686f737400';
print unpack "H*", $rdata->pack;
print "\n";
ok((unpack "H*", $rdata->pack), $expectedOutput);

# SOA
$rdata   = Net::Frame::Layer::DNS::RR::SOA->new;
$expectedOutput = 'DNS::RR::SOA: mname:localhost  rname:administrator.localhost
DNS::RR::SOA: serial:0  refresh:0  retry:0
DNS::RR::SOA: expire:0  minimum:0';
print $rdata->print . "\n";
ok($rdata->print, $expectedOutput);

$expectedOutput = '096c6f63616c686f7374000d61646d696e6973747261746f72096c6f63616c686f7374000000000000000000000000000000000000000000';
print unpack "H*", $rdata->pack;
print "\n";
ok((unpack "H*", $rdata->pack), $expectedOutput);

# SRV
$rdata = Net::Frame::Layer::DNS::RR::SRV->new;
$expectedOutput = 'DNS::RR::SRV: priority:1  weight:0  port:53
DNS::RR::SRV: target:localhost';
print $rdata->print . "\n";
ok($rdata->print, $expectedOutput);

$expectedOutput = '000100000035096c6f63616c686f737400';
print unpack "H*", $rdata->pack;
print "\n";
ok((unpack "H*", $rdata->pack), $expectedOutput);

# TXT
$rdata = Net::Frame::Layer::DNS::RR::TXT->new;
$expectedOutput = 'DNS::RR::TXT: txtdata:textdata';
print $rdata->print . "\n";
ok($rdata->print, $expectedOutput);

$expectedOutput = '087465787464617461';
print unpack "H*", $rdata->pack;
print "\n";
ok((unpack "H*", $rdata->pack), $expectedOutput);
