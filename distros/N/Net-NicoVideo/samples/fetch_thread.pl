#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;
use Getopt::Std;


my $opts = { c => 250 };
getopts('c:f',$opts);

my $video_id = $ARGV[0] or die "usage: $0 [-c num] [-f] video_id \n";

my $nnv = Net::NicoVideo->new;

my $thread = $nnv->fetch_thread($video_id, { chats => $opts->{c}, 'fork' => $opts->{f} } );

# binmode has to be set after fetch_thread, why??
binmode(STDOUT, ":utf8");

say "# there are ", $thread->count, " comments";
for my $comm ( $thread->get_comments ){
    say $comm->value;
}

1;
__END__
