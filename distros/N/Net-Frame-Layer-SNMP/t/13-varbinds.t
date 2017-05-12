use Test;
BEGIN { plan(tests => 26) }

use strict;
use warnings;

use Net::Frame::Layer::SNMP qw(:consts);

my $varbind;

$varbind = Net::Frame::Layer::SNMP->varbinds(
    oid => '1.3.6.1.4.1.50000.1.3',
    type => NF_SNMP_VARBINDTYPE_INTEGER,
    value => 1
);

ok ($varbind->{oid} eq '1.3.6.1.4.1.50000.1.3');
ok ($varbind->{value}->{integer} == 1);

$varbind = Net::Frame::Layer::SNMP->varbinds(
    oid => '1.3.6.1.4.1.50000.1.4',
    type => NF_SNMP_VARBINDTYPE_STRING,
    value => 'String'
);

ok ($varbind->{oid} eq '1.3.6.1.4.1.50000.1.4');
ok ($varbind->{value}->{string} eq 'String');

$varbind = Net::Frame::Layer::SNMP->varbinds(
    oid => '1.3.6.1.4.1.50000.1.5',
    type => NF_SNMP_VARBINDTYPE_STRING,
    value => pack 'H*', "0102030405060708"
);

ok ($varbind->{oid} eq '1.3.6.1.4.1.50000.1.5');
ok (unpack ("H*", $varbind->{value}->{string}) eq "0102030405060708");

$varbind = Net::Frame::Layer::SNMP->varbinds(
    oid => '1.3.6.1.4.1.50000.1.6',
    type => NF_SNMP_VARBINDTYPE_OID,
    value => '1.2.3.4.5.6.7.8.9'
);

ok ($varbind->{oid} eq '1.3.6.1.4.1.50000.1.6');
ok ($varbind->{value}->{oid} eq '1.2.3.4.5.6.7.8.9');

$varbind = Net::Frame::Layer::SNMP->varbinds(
    oid => '1.3.6.1.4.1.50000.1.7',
    type => NF_SNMP_VARBINDTYPE_IPADDR,
    value => '10.10.10.1'
);

ok ($varbind->{oid} eq '1.3.6.1.4.1.50000.1.7');
ok (Net::Frame::Layer::SNMP::_inetNtoa($varbind->{value}->{ipaddr}) eq '10.10.10.1');

$varbind = Net::Frame::Layer::SNMP->varbinds(
    oid => '1.3.6.1.4.1.50000.1.8',
    type => NF_SNMP_VARBINDTYPE_COUNTER32,
    value => 32323232
);

ok ($varbind->{oid} eq '1.3.6.1.4.1.50000.1.8');
ok ($varbind->{value}->{counter32} == 32323232);

$varbind = Net::Frame::Layer::SNMP->varbinds(
    oid => '1.3.6.1.4.1.50000.1.9',
    type => NF_SNMP_VARBINDTYPE_GUAGE32,
    value => 42424242
);

ok ($varbind->{oid} eq '1.3.6.1.4.1.50000.1.9');
ok ($varbind->{value}->{guage32} == 42424242);

$varbind = Net::Frame::Layer::SNMP->varbinds(
    oid => '1.3.6.1.4.1.50000.1.10',
    type => NF_SNMP_VARBINDTYPE_TIMETICKS,
    value => 1363097185
);

ok ($varbind->{oid} eq '1.3.6.1.4.1.50000.1.10');
ok ($varbind->{value}->{timeticks} == 1363097185);

$varbind = Net::Frame::Layer::SNMP->varbinds(
    oid => '1.3.6.1.4.1.50000.1.11',
    type => NF_SNMP_VARBINDTYPE_OPAQUE,
    value => 'opaque data'
);

ok ($varbind->{oid} eq '1.3.6.1.4.1.50000.1.11');
ok ($varbind->{value}->{opaque} eq 'opaque data');

$varbind = Net::Frame::Layer::SNMP->varbinds(
    oid => '1.3.6.1.4.1.50000.1.12',
    type => NF_SNMP_VARBINDTYPE_COUNTER64,
    value => 64646464
);

ok ($varbind->{oid} eq '1.3.6.1.4.1.50000.1.12');
ok ($varbind->{value}->{counter64} == 64646464);

$varbind = Net::Frame::Layer::SNMP->varbinds(
    oid => '1.3.6.1.4.1.50000.1.13',
    type => NF_SNMP_VARBINDTYPE_NULL,
    value => undef
);

ok ($varbind->{oid} eq '1.3.6.1.4.1.50000.1.13');
# When using 'null' and 'undef' value, module sets to 1 and treats special
ok (defined($varbind->{value}->{null}) == 1);

my @varbinds = Net::Frame::Layer::SNMP->v2trap_varbinds(
    oid       => '1.3.6.1.4.1.50000.1.14',
    timeticks => 600
);

ok ($varbinds[0]->{oid} eq '1.3.6.1.2.1.1.3.0');
ok ($varbinds[0]->{value}->{timeticks} == 600);
ok ($varbinds[1]->{oid} eq '1.3.6.1.6.3.1.1.4.1.0');
ok ($varbinds[1]->{value}->{oid} eq '1.3.6.1.4.1.50000.1.14');
