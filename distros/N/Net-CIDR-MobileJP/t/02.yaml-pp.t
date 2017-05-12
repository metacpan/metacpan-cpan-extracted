use strict;
use warnings;
use Test::More;
use lib 't/testlib';
use Net::CIDR::MobileJP;
use t::Utils;

# plan skip_all => 'this test requires YAML::Syck' unless $INC{'YAML/Syck.pm'};
plan tests => 3;

ok $INC{'YAML.pm'};
is $Net::CIDR::MobileJP::yaml_loader, \&YAML::LoadFile;
t::Utils->check();

