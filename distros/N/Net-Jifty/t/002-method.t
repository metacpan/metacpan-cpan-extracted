#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 18;
use lib 't/lib';
use Net::Jifty::Test;

my $j = Net::Jifty::Test->new();
$j->ua->clear();

$j->get("ping");
my ($name, $args) = $j->ua->next_call();
is($name, 'get', 'ua->get method called');
is($args->[1], 'http://jifty.org/=/ping.yml', 'correct URL');

$j->ua->clear;
$j->get([qw/foo bar/]);
($name, $args) = $j->ua->next_call();
is($name, 'get', 'ua->get method called');
is($args->[1], 'http://jifty.org/=/foo/bar.yml', 'correct URL with array-ref');

$j->ua->clear;
$j->get("foo/bar");
($name, $args) = $j->ua->next_call();
is($name, 'get', 'ua->get method called');
is($args->[1], 'http://jifty.org/=/foo/bar.yml', 'correct URL with internal /');

$j->ua->clear;
$j->get("foo/bar?baz=quux");
($name, $args) = $j->ua->next_call();
is($name, 'get', 'ua->get method called');
is($args->[1], 'http://jifty.org/=/foo/bar?baz=quux.yml', "correct URL. shouldn't try to pass arguments yourself");

$j->ua->clear;
$j->get([qw{foo bar ?baz =quux}]);
($name, $args) = $j->ua->next_call();
is($name, 'get', 'ua->get method called');
is($args->[1], 'http://jifty.org/=/foo/bar/%3Fbaz/%3Dquux.yml', 'URL is properly escaped when passed in as an array ref');

$j->ua->clear;
$j->get([qw{foo bar ?baz =quux}]);
($name, $args) = $j->ua->next_call();
is($name, 'get', 'ua->get method called');
is($args->[1], 'http://jifty.org/=/foo/bar/%3Fbaz/%3Dquux.yml', 'URL is properly escaped when passed in as an array ref');

$j->ua->clear;
$j->get([qw{foo bar ?baz =quux}], arg => 1);
($name, $args) = $j->ua->next_call();
is($name, 'get', 'ua->get method called');
is($args->[1], 'http://jifty.org/=/foo/bar/%3Fbaz/%3Dquux.yml?arg=1', '"get" query parameters work');

$j->ua->clear;
$j->get([qw{foo bar ?baz =quux}], "?-?" => "=`=");
($name, $args) = $j->ua->next_call();
is($name, 'get', 'ua->get method called');
is($args->[1], 'http://jifty.org/=/foo/bar/%3Fbaz/%3Dquux.yml?%3F-%3F=%3D%60%3D', '"get" query parameters properly escaped');

$j->ua->clear;
$j->get(["\x{2668}"], "\x{2668}" => "\x{2668}");
($name, $args) = $j->ua->next_call();
is($name, 'get', 'ua->get method called');
is($args->[1], 'http://jifty.org/=/%E2%99%A8.yml?%E2%99%A8=%E2%99%A8', '"get" query parameters properly encoded and escaped');
