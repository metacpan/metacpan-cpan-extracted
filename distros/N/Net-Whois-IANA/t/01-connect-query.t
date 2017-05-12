#!perl

use strict;
use warnings;

use Test::More (tests => 7);

use Net::Whois::IANA;

my $sock;

print STDERR "\n\nDO NOT PANIC ABOUT THE COMING ERRORS. THEY ARE OK\n\n";

$sock = Net::Whois::IANA::whois_connect('whois.ripe.net', 43, 30);
isa_ok($sock, 'IO::Socket::INET', 'socket ok');
$sock = Net::Whois::IANA::whois_connect('non-existant host', 43, 30);
ok(! $sock, "failure expected");
my $host = '132.66.16.2';
my $iana = Net::Whois::IANA->new();
isa_ok($iana, "Net::Whois::IANA", "object created");
my $query = $iana->whois_query();
is_deeply($query, {}, "failure expected empty query");
$query = $iana->whois_query(-ip => 'a.b.c.d');
is_deeply($query, {}, "failure expected non-digit ip");
$query = $iana->whois_query(-ip => '300.100.100.100');
is_deeply($query, {}, "failure expected bad IP num");
$query = $iana->whois_query(-ip => $host, -whois => 'unknown');
is_deeply($query, {}, "failure expected unknown whois server");
