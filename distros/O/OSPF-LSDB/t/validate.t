# load ospf and validate it

use strict;
use warnings;
use Test::More tests => 3;
use OSPF::LSDB::YAML;

my @yamlfiles = map { "example/ospf$_.yaml" } ("", "d", "6d");;

foreach my $yamlfile (@yamlfiles) {
    my $yaml = OSPF::LSDB::YAML->new();
    eval { $yaml->LoadFile($yamlfile) };
    ok(!$@, "$yamlfile valid") or diag($@);
}
