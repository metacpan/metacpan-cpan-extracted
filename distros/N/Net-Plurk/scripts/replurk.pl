#!perl
use strict;
use Net::Plurk;
use Net::Plurk::Plurk;
use Env qw(CONSUMER_KEY CONSUMER_SECRET ACCESS_TOKEN ACCESS_TOKEN_SECRET);
use Math::Base36 ':all';

die "Usage: replurk.pl <plurk_url>" unless $#ARGV >= 0;
my $p = Net::Plurk->new(consumer_key => $CONSUMER_KEY, consumer_secret => $CONSUMER_SECRET);
$p->authorize(token => $ACCESS_TOKEN, token_secret => $ACCESS_TOKEN_SECRET);
my $plurk_post = $p->get_plurk($ARGV[0]);
my $rep_url = encode_base36($plurk_post->plurk_id);
my $nick_name = $p->get_nick_name ($plurk_post->owner_id);
my $content = sprintf "http://www.plurk.com/p/%s (ReP): @%s: %s",
	$rep_url, $nick_name, $plurk_post->content_raw ;
# remove following line for free :p
my $trademark = ' by Net-Plurk';
$content .= $trademark
    if length($content) <= (140 - length($trademark));
$p->add_plurk($content, 'shares');
warn $p->errormsg if $p->errormsg;
