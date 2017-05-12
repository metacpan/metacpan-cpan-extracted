# load and dump ospf lsdb via yaml file interface

use strict;
use warnings;
use File::Slurp qw(slurp);
use File::Temp;
use Test::More tests => 2;

use OSPF::LSDB::YAML;

my %tmpargs = (
    SUFFIX => ".yaml",
    TEMPLATE => "ospfview-yaml-file-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my $yamlfile = "example/ospf.yaml";
my $string = slurp($yamlfile);
$string =~ s/^version: '.*'$/version: '$OSPF::LSDB::VERSION'/m;

my $yaml = OSPF::LSDB::YAML->new();
$yaml->LoadFile($yamlfile);
my $dump = $yaml->Dump();
is($dump, $string, "load file and dump string must be identical");

my $tmp = File::Temp->new(%tmpargs);
$yaml->DumpFile($tmp->filename);
my $filedump = slurp($tmp);
is($filedump, $string, "load file and dump file must be identical") or do {
    system('diff', '-up', $yamlfile, $tmp->filename);
};
