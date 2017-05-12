# load yaml file, set ipv6 flag, use with OSPF::LSDB::View must die

use strict;
use warnings;
use Test::More tests => 2;

use OSPF::LSDB::YAML;
use OSPF::LSDB::View;

my $yamlfile = "example/ospf.yaml";
my $yaml = OSPF::LSDB::YAML->new();
$yaml->LoadFile($yamlfile);

$yaml->{ospf}{ipv6} = 1;
eval { OSPF::LSDB::View->new($yaml) };
ok($@, "error view ipv6 not supported") or diag "View new did not die";
like($@, qr/^OSPF::LSDB::View does not support IPv6/, "view ipv6 not supported");
