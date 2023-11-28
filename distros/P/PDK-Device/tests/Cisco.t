#!/usr/bin/env perl

use 5.014;
use warnings;
use DDP;
# use open qw(:std :utf8);

use PDK::Device::Cisco;
use PDK::Device::H3c;
use PDK::Device::Huawei;
use PDK::Device::Juniper;
use PDK::Device::Radware;
use PDK::Device::Hillstone;
use PDK::Device::Paloalto;

my $cisco     = PDK::Device::Cisco->new(host => '192.168.8.201', password => 1122);
my $h3c       = PDK::Device::H3c->new(host => '192.168.8.201');
my $huawei    = PDK::Device::Huawei->new(host => '192.168.8.201');
my $juniper   = PDK::Device::Juniper->new(host => '192.168.8.201');
my $radware   = PDK::Device::Radware->new(host => '192.168.8.201');
my $hillstone = PDK::Device::Hillstone->new(host => '192.168.8.201');
my $paloalto  = PDK::Device::Paloalto->new(host => '192.168.8.201');

p $cisco->getConfig();
p $h3c->getConfig();
p $huawei->getConfig();
p $juniper->getConfig();
p $radware->getConfig();
p $hillstone->getConfig();
p $paloalto->getConfig();
