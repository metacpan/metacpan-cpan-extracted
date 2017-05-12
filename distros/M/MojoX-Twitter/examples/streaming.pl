#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use MojoX::Twitter;
use Data::Dumper;

my $twitter = MojoX::Twitter->new(
    consumer_key    => 'z',
    consumer_secret => 'x',
    access_token        => '1-z',
    access_token_secret => 'x',
);
$twitter->streaming('https://userstream.twitter.com/1.1/user.json', { with => 'followings' }, sub {
    my ($tweet) = @_;
    say Dumper(\$tweet);
});