#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use MojoX::Twitter;

my $twitter = MojoX::Twitter->new(
    consumer_key    => 'z',
    consumer_secret => 'x',
    access_token        => '1-z',
    access_token_secret => 'x',
);

my $res = $twitter->request('GET', 'users/show', { screen_name => 'support' });
say Dumper(\$res); use Data::Dumper;