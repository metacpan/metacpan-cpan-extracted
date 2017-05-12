#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $video_id = $ARGV[0] or die "usage: $0 video_id \n";

my $nnv = Net::NicoVideo->new;

my $watch = $nnv->fetch_watch($video_id);
for ( $watch->members ){
   say "$_: ". ($watch->$_() // '(undef)');
}

1;
__END__
