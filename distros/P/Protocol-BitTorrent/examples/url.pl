#!/usr/bin/perl 
use strict;
use warnings;

use Protocol::BitTorrent;
use File::Slurp;

my $filename = shift @ARGV;
die <<EOF unless defined $filename && length $filename;
Usage:

 $0 file.torrent

will give tracker announce URL
EOF

my $t = Protocol::BitTorrent->new;
my $torrent = read_file($filename, { binmode => ':raw' });
my $info = $t->parse_metainfo($torrent);

print "Announce URL: " . $info->announce_url(
	left	=> 8 * 1024 * 1024,
	event	=> 'started',
) . "\n";
print "Scrape URL: " . $info->scrape_url . "\n";
