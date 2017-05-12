#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;
use Data::Dumper;
local $Data::Dumper::Indent = 1;
use Getopt::Std;
use Encode::Argv ('utf8');

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $opts = { p => 1 };
getopts 'p:', $opts;

my $keyword = $ARGV[0] or die "usage: $0 [-p page] keyword\n";
my $page    = $opts->{p};

my $rss = Net::NicoVideo->new->fetch_tag_rss($keyword, { 'sort' => 'f', 'page' => $page });

say "title      : ". $rss->title;
say "description: ". $rss->description;
say "-----";

for my $item ( $rss->get_item ){
    printf '%s %s %s%s', $item->pubDate, $item->link, $item->title,"\n";
}

1;
__END__
