#!/usr/bin/env perl

use Scrappy;
use FindBin;
use Test::More $ENV{TEST_LIVE} ?
    (tests => 3) : (skip_all => 'env var TEST_LIVE not set, live testing is not enabled');

my  $s = Scrappy->new;
ok  $s->get("http://search.cpan.org/");
ok  'HTTP::Response' eq ref $s->content;
ok  $s->content->decoded_content;