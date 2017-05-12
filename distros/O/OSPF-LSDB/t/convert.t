# load ancient yaml file from times before version numbers were introduced
# convert it and compare output with current version

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

my $currentfile = "example/current.yaml";
my $current = slurp($currentfile);
$current =~ s/^version: '.*'$/version: '$OSPF::LSDB::VERSION'/m;

my $ancientfile = "example/ancient.yaml";
my $yaml = OSPF::LSDB::YAML->new();
eval { $yaml->LoadFile($ancientfile) };
ok(! $@, "load ancient") or diag("Load file example/ancient.yaml failed: $@");

my $tmp = File::Temp->new(%tmpargs);
$yaml->DumpFile($tmp->filename);
my $converted = slurp($tmp);
is($converted, $current, "current and converted must be identical") or do {
    system('diff', '-up', $currentfile, $tmp->filename);
};
