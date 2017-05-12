#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use lib 't/lib';
use Net::Jifty::Test;

my $j = Net::Jifty::Test->new();
my ($name, $args) = $j->ua->next_call();
is($name, "post", "the called method was post");
is($args->[1], "http://jifty.org/__jifty/webservices/yaml", "correct URL");

my $login = {
    'J:A-fnord'            => 'Login',
    'J:A:F-address-fnord'  => 'user@host.tld',
    'J:A:F-password-fnord' => 'password',
};

is_deeply($args->[2], $login, "correct login arguments");
is($j->sid, 'deadbeef', "get_sid was called");

# make sure we don't try to log in if we've already got a SID

$j = Net::Jifty::Test->new(sid => "ababa");
($name, $args) = $j->ua->next_call();
is($name, "cookie_jar", "didn't call post, but went right to cookie_jar");

($name, $args) = $j->ua->next_call();
is($name, undef, "no other methods called");

