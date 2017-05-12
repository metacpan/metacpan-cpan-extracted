#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;
use Net::NicoVideo::Content::NicoAPI;
use Data::Dumper;
local $Data::Dumper::Indent = 1;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $group_id    = $ARGV[0] or die "usage: $0 group_id video_id\n";
my $video_id    = $ARGV[1] or die "usage: $0 group_id video_id\n";

my $nnv = Net::NicoVideo->new;
my $mylistitem = $nnv->fetch_mylist_item($video_id);

my $api = $nnv->remove_mylist($group_id, $mylistitem, $mylistitem->token);

say 'status: '. $api->status;
unless( $api->is_status_ok ){
    say $api->error_description;
}else{
    say Data::Dumper::Dumper([$api]);
}


1;
__END__
