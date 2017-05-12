use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use File::Temp (":POSIX");
use lib 't';
use TestUtil;

sub getSession {
  my ($sn) = @_;
  my $tmpn = tmpnam();
  $sn->saveSession($tmpn);
  open TMP, "<$tmpn" or die "Unable to open $tmpn; $!";
  my $cookies = join("", <TMP>);
  close TMP;
  unlink $tmpn;
  $cookies =~ /JSESSIONID=(\w+)/;
  return $1 ? $1 : "";
}

if (TestUtil::config) { plan tests => 5 } 
else { plan skip_all => "no config" };

my $savef = tmpnam();
my $sn1 = TestUtil::getSession()->connect();
$sn1->saveSession($savef);
my $js1 = getSession($sn1);
like ($js1, qr/^\w+$/, "session=$js1");
my $location = $sn1->table("cmn_location");
my @keys = $location->getKeys();
ok (scalar(@keys), "location key read");
my $js2 = getSession($sn1);
ok ($js2 eq $js1, "session=$js2");
my $sn2 = TestUtil::getSession()->connect();
my $js3 = getSession($sn2);
ok ($js3 ne $js1, "session=$js3");
$sn2->loadSession($savef);
@keys = $location->getKeys();
my $js4 = getSession($sn2);
ok ($js4 eq $js1, "session=$js4");

1;
