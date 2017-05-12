#!/usr/bin/env perl

use Scrappy;
use Test::More $ENV{TEST_LIVE} ?
    (tests => 5) : (skip_all => 'env var TEST_LIVE not set, live testing is not enabled');

my  $s = Scrappy->new;
ok  $s->get('http://search.cpan.org/');
ok  $s->page_loaded && $s->page_status == 200;
ok  $s->get('http://search.cpan.org/recent');
ok  $s->page_loaded && $s->page_status == 200;
ok  'http://search.cpan.org/' eq $s->back;
