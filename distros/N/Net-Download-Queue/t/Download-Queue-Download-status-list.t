#!/usr/bin/perl -w
use strict;
use Data::Dumper;

use Test::More tests => 22;
use Test::Exception;

use File::Basename;
use File::Path;
use File::Spec::Functions;

use lib "../lib";

BEGIN { -d "t" and chdir("t"); }

use_ok("Net::Download::Queue");
ok(Net::Download::Queue->rebuildDatabase(), "rebuildDatabase");

ok(my $oQueue = Net::Download::Queue->new(), "new Q ok");

use_ok("Net::Download::Queue::Download");


my $pkg = "Net::Download::Queue::Download";

my $url = "http://www.darserman.com/Perl/Dylan/dylan.pl.txt";
my $file = "index.html";



print "\n* Create some downloads\n";
my $oDownload;
ok($oDownload = $pkg->create({
    url => $url,
    fileDownload => $file,
}), "create ok");
is($oDownload->bytesContent, 1540, "bytesContent ok");

ok($oDownload = $pkg->create({
    url => $url,
    fileDownload => $file,
}), "create ok");
is($oDownload->bytesDownloaded, 0, "bytesDownloaded ok");
is($oDownload->bytesContent, 1540, "bytesContent ok");

my @aDownload;
@aDownload = $pkg->retrieve_current;
is(@aDownload + 0, 2, " found 2 current");
@aDownload = $pkg->retrieve_downloading;
is(@aDownload + 0, 0, " found 0 downloading");

$oDownload->setDone;
is($oDownload->bytesDownloaded, 1540, "bytesDownloaded ok");
@aDownload = $pkg->retrieve_current;
is(@aDownload + 0, 1, " found 1 current");
@aDownload = $pkg->retrieve_downloading;
is(@aDownload + 0, 0, " found 0 downloading");

$oDownload->setDownloading;
@aDownload = $pkg->retrieve_current;
is(@aDownload + 0, 2, " found 2 current");
@aDownload = $pkg->retrieve_downloading;
is(@aDownload + 0, 1, " found 1 downloading");
is($oDownload->bytesDownloaded, 0, "bytesDownloaded 0");
ok($oDownload->setBytesDownloaded(10), "setBytesDownloaded 10");
is($oDownload->bytesDownloaded, 10, "bytesDownloaded 10");


is($oQueue->requeueDownloading(), 1, " requeueDownloading");
@aDownload = $pkg->retrieve_current;
is(@aDownload + 0, 2, " found 2 current");
$oDownload = Net::Download::Queue::Download->retrieve($oDownload->id);
is($oDownload->downloadStatusId->name, "queued", " last download is again queued");






__END__
