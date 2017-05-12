# create yaml from ospf6d files in example directory and compare

use strict;
use warnings;
use File::Slurp qw(slurp);
use File::Temp;
use Test::More tests => 2;

use OSPF::LSDB::ospf6d;
use OSPF::LSDB::YAML;

my %tmpargs = (
    SUFFIX => ".yaml",
    TEMPLATE => "ospfview-example-ospf6d-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my @values = glob("example/ospf6d.*");
my @keys = map { /\.(\w+)$/; $1; } @values;
my %files;
@files{@keys} = @values;

my $ospf6d = OSPF::LSDB::ospf6d->new();
$ospf6d->parse(%files);
eval { $ospf6d->validate() };
ok(!$@, "ospf6d valid") or diag($@);

my $yaml = OSPF::LSDB::YAML->new($ospf6d);
my $got = $yaml->Dump();
my $expected = slurp($files{yaml});
$expected =~ s/^version: '.*'$/version: '$OSPF::LSDB::VERSION'/m;
is($got, $expected, "ospf6d yaml") or do {
    my $tmp = File::Temp->new(%tmpargs);
    print $tmp $got;
    system('diff', '-up', $files{yaml}, $tmp->filename);
};
