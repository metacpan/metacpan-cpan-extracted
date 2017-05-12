#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;
use Data::Dumper;
local $Data::Dumper::Indent = 1;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $mylist_id = $ARGV[0] or die "usage: $0 mylist_id\n";

my $rss = Net::NicoVideo->new->fetch_mylist_rss($mylist_id);
say Data::Dumper::Dumper([$rss]);
say "-----";
say "title      : ". $rss->title;
say "description: ". $rss->description;

1;
__END__
