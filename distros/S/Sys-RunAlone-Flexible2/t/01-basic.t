#!perl

use strict;
use warnings;
use Test::More 0.98;

use FindBin; # just so this module is detected as dep
use File::Temp qw(tempfile);
use IPC::Run;
use Time::HiRes 'sleep';

my ($script_fh, $script_name) = tempfile();
print $script_fh <<'_';
use FindBin '$Bin';
use lib "$Bin/../lib";
use Sys::RunAlone::Flexible2;
sleep 5;
_
close $script_fh;

my $p1 = IPC::Run::start([$^X, $script_name]);
sleep 0.25;
my $p2 = IPC::Run::start([$^X, $script_name]);
ok(!$p2->finish);
$p1->finish;

done_testing;
