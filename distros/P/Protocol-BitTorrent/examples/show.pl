#!/usr/bin/perl 
use strict;
use warnings;
use Protocol::BitTorrent;
use File::Slurp;
use File::Basename;

my $bt = Protocol::BitTorrent->new;
foreach my $f (@ARGV) {
	my $torrent = read_file($f, { binmode => ':raw' });
	my $info = $bt->parse_metainfo($torrent);
	printf "%-24.24s %s\n", "$_:", $info->$_ // '' for qw(announce comment piece_length created_iso8601 created_by encoding);
	printf "%-24.24s %s\n", "Info hash:", unpack 'H*', $info->infohash;
	my $size = 0;
	foreach my $file ($info->files) {
		printf " * %s - %d bytes\n", $file->{name}, $file->{length};
		$size += $file->{length};
	}
	printf "Total size: %d bytes\n", $size;
}
