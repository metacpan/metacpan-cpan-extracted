#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
use lib 'lib';

BEGIN {
    use_ok 'Socialtext::CPANWiki';
    use_ok 'Socialtext::CPANWiki::RSSFeed';
}
