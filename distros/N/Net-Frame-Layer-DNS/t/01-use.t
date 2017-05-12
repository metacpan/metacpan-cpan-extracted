use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Layer::DNS qw(:consts);
use Net::Frame::Layer::DNS::Constants qw(:consts);
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

ok(1);
