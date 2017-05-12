#!/usr/bin/env perl

use Test::More tests => 8;

# load Scrappy
use_ok 'Scrappy';
my  $scraper = Scrappy->new;

# init Scrappy object
ok ref($scraper);

# test queue object
ok $scraper->queue;
ok ref($scraper->queue);
ok ref($scraper->queue) eq 'Scrappy::Queue';

# test session object
ok $scraper->session;
ok ref($scraper->session);
ok ref($scraper->session) eq 'Scrappy::Session';