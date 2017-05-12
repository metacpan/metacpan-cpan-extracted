use strict;
use Test::More;
use RT::Client::CLI;

use File::Spec;
my ($vol, $dir, $file) = File::Spec->splitpath(__FILE__);
my $rt = File::Spec->catpath($vol, "$dir/../script/", "rt");

ok(-e $rt, "script/rt found");
ok(system($^X, "-c", $rt) == 0, "script/rt compiles");
ok(system($^X, $rt, "help") == 0, "script/rt help exits without error");

done_testing;
