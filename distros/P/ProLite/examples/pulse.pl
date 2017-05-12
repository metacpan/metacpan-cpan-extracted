#!/usr/local/bin/perl

use lib 'blib/lib';

use ProLite qw(:core :commands :colors :styles :dingbats :effects);

my $s = new ProLite(id=>1, device=>'/dev/ttyS0', debug=>0, charDelay=>2000);

$| = 1;
print "Sending data...";

$err = $s->connect();
die "Can't connect to device - $err" if $err;

$s->wakeUp();
$s->setClock();

print ".";
$s->setPage(26, "            ...Loading...");
$s->runPage(26);

$s->setPage(25, RESET, dimRed, stackingL, "Ready.", chain(24));
$s->setPage(24, red,		appearL, "Ready.", chain(23));
$s->setPage(23, brightRed,	appearL, "Ready.", chain(24));

$s->runPage(25);


