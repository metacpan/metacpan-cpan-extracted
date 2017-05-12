#!/usr/bin/perl 
use strict;
use warnings;

use Protocol::BitTorrent;
use File::Slurp;
use Getopt::Long;

GetOptions(
	'tracker=s' => \my $trackers,
	'comment=s' => \my $comment,
	'private' => \my $private,
	'torrent=s' => \my $torrent,
);

die <<EOF unless @ARGV;
Usage:

 $0 file.torrent

will show information about the given bittorrent metadata file.
EOF

my $info = Protocol::BitTorrent::Metainfo->new(
	announce => $trackers,
	comment => $comment,
	created => time,
#	private => $private,
);
$info->add_file($_, recurse => 1) for @ARGV;
use Data::Dumper;
warn Dumper $info->as_metainfo;

binmode STDOUT;
print Protocol::BitTorrent->bencode($info->as_metainfo);

