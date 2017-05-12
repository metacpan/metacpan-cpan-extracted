#!/usr/bin/perl -w
use strict;

use Test::More tests => 21;
use Test::Exception;

use File::Basename;
use File::Path;
use File::Spec::Functions;

use lib "../lib";

BEGIN { -d "t" and chdir("t"); }


use_ok("Net::Download::Queue");
ok(Net::Download::Queue->rebuildDatabase(), "rebuildDatabase");


use_ok("Net::Download::Queue::Download");


my $pkg = "Net::Download::Queue::Download";

my $url = "http://search.cpan.org/~rjbs/Class-DBI-MSSQL-0.12/";
my $file = "index.html";

print "* domainFromUrl\n";
is($pkg->domainFromUrl(""), "", "Empty url");
is($pkg->domainFromUrl($url), "search.cpan.org", "normal url");
is($pkg->domainFromUrl('http://some:where@my.domain.com'), "my.domain.com", "url with user and pass");



print "* CDBI\n";
ok(my $oDownload = $pkg->create({
    url => $url,
    fileDownload => $file,
}), "create ok");

isnt($oDownload->id, 0, " got PK");
is($oDownload->url, $url, " url ok");
is($oDownload->fileDownload, $file, " url ok");
is($oDownload->domain, "search.cpan.org", " url ok");




print "* download\n";

my $dirDownload = "./data/download";
rmtree($dirDownload);
ok(! -d $dirDownload, " removed download temp dir");
mkpath($dirDownload);
ok(-d $dirDownload, " recreated download temp dir");
END {
    rmtree($dirDownload);
    ok(! -d $dirDownload, " removed download temp dir");
}


$url = "http://www.DarSerMan.com/Perl/TexQL/texql.pl";
$file = basename($url);
ok($oDownload = $pkg->create({
    url => $url,
    dir_download => $dirDownload,
    fileDownload => $file,
}), "create ok");

is($oDownload->downloadStatusId->name, "queued", " is queued");

ok($oDownload->download(), "download ok");
is($oDownload->downloadStatusId->name, "downloaded: ok", " is downloaded");
ok(-f "$dirDownload/$file", " got a file");

ok($oDownload->setQueued(), "setQueued ok");
is($oDownload->downloadStatusId->name, "queued", " is queued");






__END__
