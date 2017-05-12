#!/usr/bin/perl

use Net::Bonjour;
use CGI qw(:standard);

print header, start_html('Bonjour Websites'), h1('Bonjour Websites'),
	hr;

my $res = new Net::Bonjour('http');
$res->discover;

foreach $entry ( $res->entries ) {
	my $url = sprintf 'http://%s:%s%s', $entry->address, $entry->port,
		$entry->attribute('path');
	print a({-href=> $url}, $entry->name), br;
}
