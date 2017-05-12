#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $video_id = $ARGV[0] or die "usage: $0 video_id file\n";
my $file     = $ARGV[1] or die "usage: $0 video_id file\n";

my $nnv = Net::NicoVideo->new;
$nnv->download($video_id, $file);

1;
__END__
