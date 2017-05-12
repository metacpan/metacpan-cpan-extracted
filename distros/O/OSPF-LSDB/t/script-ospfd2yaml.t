# run perl script ospfd2yaml

use strict;
use warnings;
use File::Slurp qw(slurp);
use File::Temp;
use Test::More tests => 2 * 3;

my %tmpargs = (
    SUFFIX => ".yaml",
    TEMPLATE => "ospfview-script-ospfd2yaml-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my $tmp = File::Temp->new(%tmpargs);

$0 = "script/ospfd2yaml";
@ARGV = (
    '-B', "example/ospfd.boundary",
    '-E', "example/ospfd.external",
    '-I', "example/ospfd.selfid",
    '-N', "example/ospfd.network",
    '-R', "example/ospfd.router",
    '-S', "example/ospfd.summary",
    $tmp->filename);
undef *main;
undef *usage;
my $done = do $0;
ok(!$@, "$0 parse") or diag("Parse $0 failed: $@");
ok(defined $done, "$0 do") or diag("Do $0 failed: $!");
ok($done, "$0 run") or diag("Run $0 failed");

@ARGV = (
    '-6',
    '-B', "example/ospf6d.boundary",
    '-E', "example/ospf6d.external",
    '-I', "example/ospf6d.selfid",
    '-L', "example/ospf6d.link",
    '-N', "example/ospf6d.network",
    '-P', "example/ospf6d.intra",
    '-R', "example/ospf6d.router",
    '-S', "example/ospf6d.summary",
    $tmp->filename);
undef *main;
undef *usage;
$done = do $0;
ok(!$@, "$0 parse 6") or diag("Parse $0 -6 failed: $@");
ok(defined $done, "$0 do 6") or diag("Do $0 -6 failed: $!");
ok($done, "$0 run 6") or diag("Run $0 -6 failed");
