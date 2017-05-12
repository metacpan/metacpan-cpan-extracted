#!perl

use Test::More tests => 2;

use Net::Google::SafeBrowsing::UpdateRequest;
use File::Temp qw(tempfile);

sub runcmd {
  diag(@_);
  return system(@_);
}

my $updater = "$^X ./blocklist_updater";
my $update = 'testdata/update.txt';
my $update01 = 'testdata/update01.txt';
my $getkey = 'testdata/getkey.txt';

my ($fh, $tmpdb) = tempfile();
close($fh);

ok(not runcmd("$updater --apikey=NotUsed --dbfile=$tmpdb " .
              "--blocklist=goog-black-hash --keysfile=$getkey ".
              "--updatefile=$update"));
ok(not runcmd("$updater --apikey=NotUsed --dbfile=$tmpdb " .
              "--blocklist=goog-black-hash --keysfile=$getkey ".
              "--updatefile=$update01 --skip_mac"));
