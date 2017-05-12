# run perl script ospfconvert

use strict;
use warnings;
use File::Slurp qw(slurp);
use File::Temp;
use Test::More tests => 4;

use OSPF::LSDB;

my %tmpargs = (
    SUFFIX => ".yaml",
    TEMPLATE => "ospfview-script-ospfconvert-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my $tmp = File::Temp->new(%tmpargs);

$0 = "script/ospfconvert";
@ARGV = ("example/old.yaml", $tmp->filename);
my $done = do $0;
ok(!$@, "$0 parse") or diag("Parse $0 failed: $@");
ok(defined $done, "$0 do") or diag("Do $0 failed: $!");
ok($done, "$0 run") or diag("Run $0 failed");

my $expected = slurp("example/all.yaml");
$expected =~ s/^version: '.*'$/version: '$OSPF::LSDB::VERSION'/m;
is(slurp($tmp), $expected, "output") or do {
    diag("example/old.yaml not converted to example/all.yaml");
    system('diff', '-up', "example/all.yaml", $tmp->filename);
};
