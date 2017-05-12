#!/usr/bin/env perl

use Scrappy;
use FindBin;
use Test::More $ENV{TEST_LIVE} ?
    (tests => 2) : (skip_all => 'env var TEST_LIVE not set, live testing is not enabled');

my  $s = Scrappy->new;
    $s->get("http://www.perl.org/");
ok  $s->domain eq 'www.perl.org';
    $s->get("http://search.cpan.org/");
ok  $s->domain eq 'search.cpan.org';