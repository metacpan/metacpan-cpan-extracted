# create yaml from ospfd files in example directory and compare

use strict;
use warnings;
use File::Slurp qw(slurp);
use File::Temp;
use Test::More tests => 2;

use OSPF::LSDB::ospfd;
use OSPF::LSDB::YAML;

my %tmpargs = (
    SUFFIX => ".yaml",
    TEMPLATE => "ospfview-example-ospfd-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my @values = glob("example/ospfd.*");
my @keys = map { /\.(\w+)$/; $1; } @values;
my %files;
@files{@keys} = @values;

my $ospfd = OSPF::LSDB::ospfd->new();
$ospfd->parse(%files);
eval { $ospfd->validate() };
ok(!$@, "ospfd valid") or diag($@);

my $yaml = OSPF::LSDB::YAML->new($ospfd);
my $got = $yaml->Dump();
my $expected = slurp($files{yaml});
$expected =~ s/^version: '.*'$/version: '$OSPF::LSDB::VERSION'/m;
is($got, $expected, "ospfd yaml") or do {
    my $tmp = File::Temp->new(%tmpargs);
    print $tmp $got;
    system('diff', '-up', $files{yaml}, $tmp->filename);
};
