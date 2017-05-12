#!/usr/bin/env perl

use Scrappy;
use FindBin;
use Test::More $ENV{TEST_LIVE} ?
    (tests => 2) : (skip_all => 'env var TEST_LIVE not set, live testing is not enabled');

my  $s = Scrappy->new;
my  $d = "$FindBin::Bin/htdocs";

ok  $s->download('http://search.cpan.org/', $d, 'search.cpan.org.html');
ok  -f "$d/search.cpan.org.html"; unlink "$d/search.cpan.org.html";