#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new();

&main;exit;

sub get {
    my $url = shift;
    my $res = $ua->get($url);
    $res->is_success or die "cannot get $url";
    $res;
}

sub get_xrds_location {
    my $entry_point = shift;
    my $res = get($entry_point);
    my $xrds_location = $res->header('X-XRDS-Location') or die 'x-xrds-location not found';
    return $xrds_location;
}

sub main {
    my $url = shift @ARGV or die "Usage: $0 https://mixi.jp/\n";
    my $xrds = get(get_xrds_location($url))->content;
    if ($xrds =~ m{<URI>([^<>]+)</URI>}) {
        print "Entry point is : $1\n";
    } else {
        print "xrds not found: $xrds\n";
    }
}
