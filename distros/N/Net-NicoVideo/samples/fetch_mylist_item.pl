#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $video_id = $ARGV[0] or die "usage: $0 video_id\n";

my $item = Net::NicoVideo->new->fetch_mylist_item($video_id);
say "video_id   : ". $video_id;
say "token      : ". $item->token;
say "item_type  : ". $item->item_type;
say "item_id    : ". $item->item_id;
say "description: ". $item->description;

1;
__END__
