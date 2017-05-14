#!/usr/bin/env perl 
use v5.10;

use lib qw{ lib };
use Periscope;
use Data::Dump qw(dump);

die "Usage: $0 URL" unless @ARGV;

my $p = Periscope->new(address => $ARGV[0]);
$p->event('download-requested' => sub {
	my $view     = shift;
	my $download = shift;
	my $url      = $download->get_uri;

	say "downloading $url...";
	system("wget $url");

	return FALSE;
});
$p->show;
