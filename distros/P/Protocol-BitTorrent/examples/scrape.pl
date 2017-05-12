#!/usr/bin/perl 
use strict;
use warnings;

use Protocol::BitTorrent;
use File::Slurp;
use LWP::UserAgent;
use Data::Dumper;

my $filename = shift @ARGV;
die <<EOF unless defined $filename && length $filename;
Usage:

 $0 file.torrent

will give tracker announce URL
EOF

my $t = Protocol::BitTorrent->new;
my $torrent = read_file($filename, { binmode => ':raw' });
my $info = $t->parse_metainfo($torrent);

print "Checking scrape URL: " . $info->scrape_url . "\n";
my $ua = LWP::UserAgent->new;
my $rslt = $ua->get($info->scrape_url);

=pod

$VAR1 = {
          'peers' => '�K�K�"',
          'incomplete' => '2',
          'downloaded' => '0',
          'interval' => '1753',
          'min interval' => '876',
          'complete' => '0'
        };

=cut

if($rslt->is_success) {
	my $data = $t->bdecode($rslt->content);
	print "Seeders:  " . $data->{complete} . "\n";
	print "Leechers: " . $data->{incomplete} . "\n";
	print "Complete downloads so far: " . $data->{downloaded} . "\n";

	print "Interval:     " . $data->{interval} . "s\n" if defined $data->{interval};
	print "Min interval: " . $data->{'min interval'} . "s\n" if defined $data->{'min interval'};

} else {
	die $rslt->status_line;
}

