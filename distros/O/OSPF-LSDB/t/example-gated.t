# create yaml from gated dump in example directory and compare

use strict;
use warnings;
use File::Slurp qw(slurp);
use File::Temp;
use Test::More tests => 2;

use OSPF::LSDB::gated;
use OSPF::LSDB::YAML;

my %tmpargs = (
    SUFFIX => ".yaml",
    TEMPLATE => "ospfview-example-gated-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my $dumpfile = "example/gated.dump";
my $yamlfile = "example/gated.yaml";

my $gated = OSPF::LSDB::gated->new();
$gated->parse(file => $dumpfile);
eval { $gated->validate() };
ok(!$@, "gated valid") or diag($@);

my $yaml = OSPF::LSDB::YAML->new($gated);
my $got = $yaml->Dump();
my $expected = slurp($yamlfile);
$expected =~ s/^version: '.*'$/version: '$OSPF::LSDB::VERSION'/m;
is($got, $expected, "gated yaml") or do {
    my $tmp = File::Temp->new(%tmpargs);
    print $tmp $got;
    system('diff', '-up', $yamlfile, $tmp->filename);
};
