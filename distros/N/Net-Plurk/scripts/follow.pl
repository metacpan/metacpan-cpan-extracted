#!perl
use strict;
use Net::Plurk;
use Env qw(CONSUMER_KEY CONSUMER_SECRET ACCESS_TOKEN ACCESS_TOKEN_SECRET);
my $p = Net::Plurk->new(consumer_key => $CONSUMER_KEY, consumer_secret => $CONSUMER_SECRET);
$p->authorize(token => $ACCESS_TOKEN, token_secret => $ACCESS_TOKEN_SECRET);
my $profile = $p->get_public_profile ( 'clsung' );
my $user_info = $profile->{user_info};
warn $p->follow($user_info->id);
warn $p->errormsg if $p->errormsg;
