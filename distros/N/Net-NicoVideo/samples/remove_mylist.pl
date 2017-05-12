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

my $group_id    = $ARGV[0] or die "usage: $0 group_id item_id\n";
my $item_id     = $ARGV[1] or die "usage: $0 group_id item_id\n";

my $item = Net::NicoVideo::Content::NicoAPI::MylistItem->new({
    item_type   => 0,
    item_id     => $item_id,
    });

my $nnv = Net::NicoVideo->new;
my $api = $nnv->remove_mylist($group_id, $item);

say 'status: '. $api->status;
unless( $api->is_status_ok ){
    say $api->error_description;
}else{
    say Data::Dumper::Dumper([$api]);
    say ref($api);
}

1;
__END__
