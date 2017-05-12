#!/usr/bin/perl -w

use lib 'lib';
use Test;
use strict;
use Nmap::Scanner;
use constant FILE1 => 't/victor.xml';
use constant FILE2 => 't/router.xml';
use constant URL1 => 'http://nmap-scanner.sf.net/scan-test.xml';

BEGIN { plan tests => 7 }

my $scanner = Nmap::Scanner->new();
$scanner->debug(1);
my $scan = $scanner->scan_from_file(FILE1);

ok($scan);

my $host = $scan->get_host_list()->get_next();
ok(sub { ($host->addresses())[0]->addr() ne "" });

my $aport = $host->get_port_list()->get_next();
ok($aport->portid());

$scan = $scanner->scan_from_file(FILE2);

ok($scan);

$host = $scan->get_host_list()->get_next();
ok(sub { ($host->addresses())[0]->addr() ne "" });

$aport = $host->get_port_list()->get_next();
ok($aport->portid());

#  Retrieve scan from URL on Nmap::Scanner SF.net project site
$scan = $scanner->scan_from_file(URL1);
ok($scan);

1;
