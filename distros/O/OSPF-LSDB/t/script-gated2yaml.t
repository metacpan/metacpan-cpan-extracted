# run perl script gated2yaml

use strict;
use warnings;
use File::Slurp qw(slurp);
use File::Temp;
use Test::More tests => 3;

my %tmpargs = (
    SUFFIX => ".yaml",
    TEMPLATE => "ospfview-script-gated2yaml-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my $tmp = File::Temp->new(%tmpargs);

$0 = "script/gated2yaml";
@ARGV = ('-D', "example/gated.dump", $tmp->filename);
my $done = do $0;
ok(!$@, "$0 parse") or diag("Parse $0 failed: $@");
ok(defined $done, "$0 do") or diag("Do $0 failed: $!");
ok($done, "$0 run") or diag("Run $0 failed");
