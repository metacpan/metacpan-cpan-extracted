#!/usr/bin/env perl

use Test::More tests => 12;

# load Scrappy
use_ok 'Scrappy';
my  $s = Scrappy->new;

# test attributes and return value
ok 'Scrappy' eq ref $s ;
ok undef eq ref $s->content ;
ok 'Scrappy::Scraper::Control' eq ref $s->control ;
ok 1 == $s->debug ;
ok 'Scrappy::Logger' eq ref $s->logger ;
ok 'Scrappy::Scraper::Parser' eq ref $s->parser ;
ok 'Scrappy::Plugin' eq ref $s->plugins ;
ok 'Scrappy::Queue' eq ref $s->queue ;
ok 'Scrappy::Session' eq ref $s->session ;
ok 'Scrappy::Scraper::UserAgent' eq ref $s->user_agent ;
ok 'WWW::Mechanize' eq ref $s->worker ;
