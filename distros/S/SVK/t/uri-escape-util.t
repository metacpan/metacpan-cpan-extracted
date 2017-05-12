#!/usr/bin/perl -w
use strict;
use SVK::Test;
use SVK::Util qw(uri_escape uri_unescape);

# test uri escape here
# key for input, value for output
my %uris = (
    'svn+ssh://foo@bar.bestpractical.com/svn/bps-nonsense'
    => 'svn+ssh://foo@bar.bestpractical.com/svn/bps-nonsense',
    'http://bar.bestpractical.com/svn/bps-nonsense'
    => 'http://bar.bestpractical.com/svn/bps-nonsense',
    'http://bar.bestpractical.com/B and K/A/N P1/trunk'
    => 'http://bar.bestpractical.com/B%20and%20K/A/N%20P1/trunk',
);

plan tests => (scalar keys %uris);

for my $uri (keys %uris) {
    is (uri_escape($uri), $uris{$uri});
}
