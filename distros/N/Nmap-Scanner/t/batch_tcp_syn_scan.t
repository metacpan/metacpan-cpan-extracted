#!/usr/bin/perl

use lib 'lib';

use Test;
use Nmap::Scanner;
use strict;

BEGIN { plan tests => 3 }

my $scan = Nmap::Scanner->new();

ok($scan);

my $SKIP = Nmap::Scanner::Scanner::_find_nmap() ? 0 : 
           "nmap not found in PATH (See http://www.insecure.org/nmap/)";

if ($SKIP) {
    skip($SKIP);
    skip($SKIP);
    exit;
}
$scan->add_target('localhost');
$scan->add_scan_port('1-1024');
$scan->tcp_connect_scan();

my $localhost = $scan->scan()->get_host_list()->get_next();
ok(sub { $localhost->hostname() ne '' });

my $aport = $localhost->get_port_list()->get_next();
ok($aport->portid());
