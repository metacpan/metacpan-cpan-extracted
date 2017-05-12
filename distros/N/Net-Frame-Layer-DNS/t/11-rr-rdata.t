use Test;
BEGIN { plan(tests => 10) }

use strict;
use warnings;

my $NO_HAVE_NetFrameSimple = 0;
eval "use Net::Frame::Simple 1.05";
if($@) {
    $NO_HAVE_NetFrameSimple = "Net::Frame::Simple 1.05 required";
}

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
use Net::Frame::Layer::DNS::RR::SOA;
use Net::Frame::Layer::DNS::RR::SRV;
use Net::Frame::Layer::DNS::RR::TXT;

my ($rdata, $rr, $packet, $decode, $expectedOutput);

# A
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::A->new;
$rr    = Net::Frame::Layer::DNS::RR->new(rdata=>$rdata->pack);

$packet = $rr->pack;

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'DNS::RR'
);

$expectedOutput = 'DNS::RR: name:localhost
DNS::RR: type:1  class:1  ttl:0  rdlength:4
DNS::RR::A: address:127.0.0.1';

print $decode->print . "\n";

$decode->print eq $expectedOutput;
});

# AAAA
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::AAAA->new;
$rr    = Net::Frame::Layer::DNS::RR->new(
    type  => NF_DNS_TYPE_AAAA,
    rdata => $rdata->pack
);

$packet = $rr->pack;

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'DNS::RR'
);

$expectedOutput = 'DNS::RR: name:localhost
DNS::RR: type:28  class:1  ttl:0  rdlength:16
DNS::RR::AAAA: address:::1';

print $decode->print . "\n";

$decode->print eq $expectedOutput;
});

# CNAME
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::CNAME->new;
$rr    = Net::Frame::Layer::DNS::RR->new(
    type  => NF_DNS_TYPE_CNAME,
    rdata => $rdata->pack
);

$packet = $rr->pack;

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'DNS::RR'
);

$expectedOutput = 'DNS::RR: name:localhost
DNS::RR: type:5  class:1  ttl:0  rdlength:11
DNS::RR::CNAME: cname:localhost';

print $decode->print . "\n";

$decode->print eq $expectedOutput;
});

# HINFO
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::HINFO->new;
$rr    = Net::Frame::Layer::DNS::RR->new(
    type  => NF_DNS_TYPE_HINFO,
    rdata => $rdata->pack
);

$packet = $rr->pack;

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'DNS::RR'
);

$expectedOutput = 'DNS::RR: name:localhost
DNS::RR: type:13  class:1  ttl:0  rdlength:11
DNS::RR::HINFO: cpu:PC  os:Windows';

print $decode->print . "\n";

$decode->print eq $expectedOutput;
});

# MX
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::MX->new;
$rr    = Net::Frame::Layer::DNS::RR->new(
    type  => NF_DNS_TYPE_MX,
    rdata => $rdata->pack
);

$packet = $rr->pack;

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'DNS::RR'
);

$expectedOutput = 'DNS::RR: name:localhost
DNS::RR: type:15  class:1  ttl:0  rdlength:13
DNS::RR::MX: preference:1
DNS::RR::MX: exchange:localhost';

print $decode->print . "\n";

$decode->print eq $expectedOutput;
});

# NS
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::NS->new;
$rr    = Net::Frame::Layer::DNS::RR->new(
    type  => NF_DNS_TYPE_NS,
    rdata => $rdata->pack
);

$packet = $rr->pack;

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'DNS::RR'
);

$expectedOutput = 'DNS::RR: name:localhost
DNS::RR: type:2  class:1  ttl:0  rdlength:11
DNS::RR::NS: nsdname:localhost';

print $decode->print . "\n";

$decode->print eq $expectedOutput;
});

# PTR
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::PTR->new;
$rr    = Net::Frame::Layer::DNS::RR->new(
    type  => NF_DNS_TYPE_PTR,
    rdata => $rdata->pack
);

$packet = $rr->pack;

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'DNS::RR'
);

$expectedOutput = 'DNS::RR: name:localhost
DNS::RR: type:12  class:1  ttl:0  rdlength:11
DNS::RR::PTR: ptrdname:localhost';

print $decode->print . "\n";

$decode->print eq $expectedOutput;
});

# SOA
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::SOA->new;
$rr    = Net::Frame::Layer::DNS::RR->new(
    type  => NF_DNS_TYPE_SOA,
    rdata => $rdata->pack
);

$packet = $rr->pack;

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'DNS::RR'
);

$expectedOutput = 'DNS::RR: name:localhost
DNS::RR: type:6  class:1  ttl:0  rdlength:56
DNS::RR::SOA: mname:localhost  rname:administrator.localhost
DNS::RR::SOA: serial:0  refresh:0  retry:0
DNS::RR::SOA: expire:0  minimum:0';

print $decode->print . "\n";

$decode->print eq $expectedOutput;
});

# SRV
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::SRV->new;
$rr    = Net::Frame::Layer::DNS::RR->new(
    type  => NF_DNS_TYPE_SRV,
    rdata => $rdata->pack
);

$packet = $rr->pack;

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'DNS::RR'
);

$expectedOutput = 'DNS::RR: name:localhost
DNS::RR: type:33  class:1  ttl:0  rdlength:17
DNS::RR::SRV: priority:1  weight:0  port:53
DNS::RR::SRV: target:localhost';

print $decode->print . "\n";

$decode->print eq $expectedOutput;
});

# TXT
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::TXT->new;
$rr    = Net::Frame::Layer::DNS::RR->new(
    type  => NF_DNS_TYPE_TXT,
    rdata => $rdata->pack
);

$packet = $rr->pack;

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'DNS::RR'
);

$expectedOutput = 'DNS::RR: name:localhost
DNS::RR: type:16  class:1  ttl:0  rdlength:9
DNS::RR::TXT: txtdata:textdata';

print $decode->print . "\n";

$decode->print eq $expectedOutput;
});
