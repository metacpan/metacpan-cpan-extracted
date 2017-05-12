# create yaml from cisco files in example directory and compare

use strict;
use warnings;
use File::Slurp qw(slurp);
use File::Temp;
use Test::More tests => 2;

use OSPF::LSDB::Cisco;
use OSPF::LSDB::YAML;

my %tmpargs = (
    SUFFIX => ".yaml",
    TEMPLATE => "ospfview-example-cisco-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my @values = glob("example/cisco.*");
my @keys = map { /\.(\w+)$/; $1; } @values;
my %files;
@files{@keys} = @values;

my $cisco = OSPF::LSDB::Cisco->new();
$cisco->parse(%files);
eval { $cisco->validate() };
ok(!$@, "cisco valid") or diag($@);

my $yaml = OSPF::LSDB::YAML->new($cisco);
my $got = $yaml->Dump();
my $expected = slurp($files{yaml});
$expected =~ s/^version: '.*'$/version: '$OSPF::LSDB::VERSION'/m;
is($got, $expected, "cisco yaml") or do {
    my $tmp = File::Temp->new(%tmpargs);
    print $tmp $got;
    system('diff', '-up', $files{yaml}, $tmp->filename);
};
