#!/usr/bin/perl 
use strict;
use warnings;

use Protocol::BitTorrent;
use File::Slurp;

my $filename = shift @ARGV;
die <<EOF unless defined $filename && length $filename;
Usage:

 $0 file.torrent

will show information about the given bittorrent metadata file.
EOF

my $t = Protocol::BitTorrent->new;
my $torrent = read_file($filename, { binmode => ':raw' });
my $info = $t->parse_metainfo($torrent);
foreach (qw(announce comment infohash)) {
	my $data = $info->$_;
	next unless defined $data;
	$data = unpack 'H*', $info->infohash if $_ eq 'infohash';
	printf "%-32.32s %s\n", $_ . ':', $data;
}

