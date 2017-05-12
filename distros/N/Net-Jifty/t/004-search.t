#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 18;
use lib 't/lib';
use Net::Jifty::Test;

my $j = Net::Jifty::Test->new();

search('http://jifty.org/=/search/Foo/id/1/created/today.yml',
    "Foo", id => 1, created => "today");

search('http://jifty.org/=/search/Foo/id/1/id/2/created/today.yml',
    "Foo", id => 1, id => 2, created => "today");

search('http://jifty.org/=/search/Foo/id/1/id/2/created/today.yml',
    "Foo", id => [1, 2], created => "today");

search('http://jifty.org/=/search/Foo/id/1/created/today/out.yml',
    "Foo", id => 1, created => "today", "out");

search('http://jifty.org/=/search/Foo/id/1/id/2/created/today/out.yml',
    "Foo", id => 1, id => 2, created => "today", "out");

search('http://jifty.org/=/search/Foo/id/1/id/2/created/today/out.yml',
    "Foo", id => [1, 2], created => "today", "out");

search('http://jifty.org/=/search/Foo/id/1/id/2/id.yml',
    "Foo", id => [1, 2], "id");

search('http://jifty.org/=/search/Foo/id/1/id/2/id/3/id/4/id.yml',
    "Foo", id => [1, 2], id => [3, 4], "id");

search('http://jifty.org/=/search/Foo/id/1/id/2/inner/hi/id/3/id/4/id.yml',
    "Foo", id => [1, 2], inner => "hi", id => [3, 4], "id");

sub search {
    my $url = shift;
    my @args = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $j->ua->clear;
    $j->search(@_);
    my ($name, $args) = $j->ua->next_call();
    is($name, 'get', 'ua->get method called for search');
    is($args->[1], $url, 'correct URL');
}

