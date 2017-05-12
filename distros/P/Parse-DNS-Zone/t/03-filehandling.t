#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('Parse::DNS::Zone') }

my $origin = 'example.com.';
my $zonefile = 't/data/db.simple';
my $zonestr = do {
	local $/;
	open my $fh, '<', $zonefile or die("Could not open $zonefile: $!");
	<$fh>
};

my $from_str = Parse::DNS::Zone->new(
	zonestr => $zonestr,
	basepath => 't/data',
	origin => $origin,
);

my $from_file = Parse::DNS::Zone->new(
	zonefile => $zonefile,
	origin => $origin,
);

is(
	int $from_file->get_names, int $from_str->get_names,
	"expected number of names in zone"
);

is(
	$from_str->get_rdata(name=>'@', rr=>'A'),
	$from_file->get_rdata(name=>'@', rr=>'A'),
	'get_rdata("@", "A")'
);

is(
	int $from_str->get_dupes(name => '@', rr => 'NS'),
	int $from_file->get_dupes(name => '@', rr => 'NS'),
	'get_dupes("@", "NS")'
);
