# load and dump ospf lsdb via yaml string interface

use strict;
use warnings;
use File::Temp;
use Test::More tests => 1;

use OSPF::LSDB::YAML;

my %tmpargs = (
    SUFFIX => ".yaml",
    TEMPLATE => "ospfview-yaml-string-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my $string = <<EOF;
--- 
database: 
  boundarys: []

  externals: []

  intranetworks: []

  intrarouters: []

  links: []

  networks: 
    - 
      address: 0.0.1.1
      area: 1.0.0.0
      attachments: 
        - 
          routerid: 0.1.0.0
      netmask: 255.255.255.0
      routerid: 0.1.0.0
    - 
      address: 0.0.1.2
      area: 1.0.0.0
      attachments: 
        - 
          routerid: 0.1.0.0
      netmask: 255.255.255.128
      routerid: 0.1.0.0
    - 
      address: 0.0.2.1
      area: 2.0.0.0
      attachments: 
        - 
          routerid: 0.1.0.0
      netmask: 255.255.255.0
      routerid: 0.1.0.0
  routers: 
    - 
      area: 1.0.0.0
      bits: 
        B: 1
        E: 1
        V: 0
      pointtopoints: []

      router: 0.1.0.0
      routerid: 0.1.0.0
      stubs: []

      transits: []

      virtuals: []

    - 
      area: 2.0.0.0
      bits: 
        B: 1
        E: 1
        V: 0
      pointtopoints: []

      router: 0.1.0.0
      routerid: 0.1.0.0
      stubs: []

      transits: []

      virtuals: []

  summarys: []

ipv6: 0
self: 
  areas: 
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
version: '$OSPF::LSDB::VERSION'
EOF

my $yaml = OSPF::LSDB::YAML->new();
$yaml->Load($string);
my $dump = $yaml->Dump();
is($dump, $string, "load string and dump string must be identical") or do {
    my $s = File::Temp->new(%tmpargs);
    print $s $string;
    my $d = File::Temp->new(%tmpargs);
    print $d $dump;
    system('diff', '-up', $s->filename, $d->filename);
};
