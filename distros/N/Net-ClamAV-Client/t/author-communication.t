#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Try::Tiny;
my $nrTests=0;

use_ok( 'Net::ClamAV::Client' );
$nrTests++;

my $client;

my $ok = 1;
try {
  $client = Net::ClamAV::Client->new(url => "localhost:3311");
  $client->ping();
}
catch
{
  $ok = 0;
};

ok($ok == 0, "Ping without running clamd");

$nrTests++;

$ok = 1;
try {
  $client->version();
}
catch
{
  $ok = 0;
};
ok($ok == 0, "Version without running clamd");
$nrTests++;

$ok = 1;
try {
  $client->reload();
}
catch
{
  $ok = 0;
};
ok($ok == 0, "Reload without running clamd");
$nrTests++;

$ok = 1;
try {
  $client->shutdown();
}
catch
{
  $ok = 0;
};
ok($ok == 0, "Shutdown without running clamd");
$nrTests++;

$ok = 1;
try {
  $client->quit();
}
catch
{
  $ok = 0;
};
ok($ok == 0, "Quit without running clamd");
$nrTests++;

$ok = 1;
try {
  $client->scanLocalPath("./");
}
catch
{
  $ok = 0;
};
ok($ok == 0, "scanLocalPath without running clamd");
$nrTests++;

$ok = 1;
try {
  $client->scanLocalPathContinous("./");
}
catch
{
  $ok = 0;
};
ok($ok == 0, "scanLocalPathContinous without running clamd");
$nrTests++;

$ok = 1;
try {
  $client->scanLocalPathMulti("./");
}
catch
{
  $ok = 0;
};
ok($ok == 0, "scanLocalPathMulti without running clamd");
$nrTests++;

$ok = 1;
try {
  $client->scanLocalFile("eicar.com");
}
catch
{
  $ok = 0;
};
ok($ok == 0, "scanLocalFile without running clamd");
$nrTests++;

$ok = 1;
try {
  $client->startSession();
}
catch
{
  $ok = 0;
};
ok($ok == 0, "startSession without running clamd");
$nrTests++;

$ok = 1;
try {
  $client->endSession();
}
catch
{
  $ok = 0;
};
ok($ok == 0, "endSession without running clamd");
$nrTests++;



$ok = 1;
my $reply;
try {
  $client = Net::ClamAV::Client->new(url => "localhost:3310");
  $reply=$client->ping();
}
catch
{
  $ok = 0;
};

ok($ok == 1, "Ping with running clamd");
$nrTests++;
ok($reply eq "PONG", "Ping returns PONG");
$nrTests++;

$ok = 1;
try {
  $reply = $client->version();
}
catch
{
  $ok = 0;
};
ok($ok == 1, "version with running clamd");
$nrTests++;
ok($reply =~ /^ClamAV\s\d+/, "Version returns a version");
$nrTests++;

$ok = 1;
try {
  $reply = $client->reload();
}
catch
{
  $ok = 0;
};
ok($ok == 1, "reload with running clamd");
$nrTests++;
ok($reply eq "RELOADING", "Reload returns RELOADING");
$nrTests++;

$ok = 1;
my $error="";
try {
  readpipe("mkdir -p /tmp/test-clam; cp eicar.com /tmp/test-clam/");
  $reply = $client->scanLocalPath("/tmp/test-clam");
  readpipe("rm -rf /tmp/test-clam");
}
catch
{
  $error=$_;
  $ok = 0;
};
ok($ok == 1, "scanLocalPath with running clamd");
$nrTests++;
ok($reply->{file} eq "/tmp/test-clam/eicar.com" && $reply->{result} eq "Win.Test.EICAR_HDB-1" , "Found Eicar Test Virus");
$nrTests++;
done_testing($nrTests);
