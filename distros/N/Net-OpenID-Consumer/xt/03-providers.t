#!/usr/bin/perl
use strict;
use warnings;
use Net::OpenID::Consumer;
use Test::More;

my @tests = qw(
    https://www.google.com/accounts/o8/id 
    http://openid.aol.com/joe
    http://test.myopenid.com/
    http://flickr.com/test/
    http://test.wordpress.com/
    http://test.blogspot.com/
    http://test.myvidoop.com/
    http://claimid.com/test/
    http://lj.livejournal.com/
    http://me.yahoo.com
); #    http://technorati.com/people/technorati/test


{
    use integer;
    plan tests => scalar @tests;
}

for my $url ( @tests ) {
    my $csr = Net::OpenID::Consumer->new;
    my $identity = $csr->claimed_identity($url);
    ok $identity, "Got a claimed identity for $url";
}
