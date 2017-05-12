#!/usr/bin/perl -w
use strict;

use Test::More tests => 18;
use Test::Exception;
use File::Basename;

use Data::Dumper;

use lib "../lib";

BEGIN { -d "t" and chdir("t"); }


use_ok("Net::Download::Queue");

ok(Net::Download::Queue->rebuildDatabase(), "rebuildDatabase ok");



ok(my $oQ = Net::Download::Queue->new(), "new ok");


is($oQ->oDownloadDequeue(), undef, "Can't get download, none in queue");


my $url = "http://www.darserman.com/Perl/db/syb2ora.pl";
my $file = basename($url);
ok(my $oDownload = $oQ->oDownloadAdd($url, "./download", $file), "oDownloadAdd ok");
is($oDownload->url, $url, " url ok");
is($oDownload->urlReferer, "", " urlReferer ok");
is($oDownload->bytesContent, 6829, " bytesContent ok");

ok(my $oDownloading = $oQ->oDownloadDequeue(), "Got something to download");

is($oDownloading->downloadStatusId->name, "downloading", " correct status");
is($oDownloading->url, $url, " correct url");

is($oQ->oDownloadDequeue(), undef, "Can't get download, none in queue");


ok($oDownloading->setDone, " download done ok");
is($oDownloading->downloadStatusId->name, "downloaded: ok", " download status done ok");

is($oQ->oDownloadDequeue(), undef, "Can't get download, none in queue");


my $urlReferer = "http://www.sunet.se/";
ok($oDownload = $oQ->oDownloadAdd($url, "./download", $file, $urlReferer), "oDownloadAdd ok");
is($oDownload->url, $url, " url ok");
is($oDownload->urlReferer, $urlReferer, " urlReferer ok");





__END__
