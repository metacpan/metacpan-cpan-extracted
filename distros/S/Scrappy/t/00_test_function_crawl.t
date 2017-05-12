#!/usr/bin/env perl

use Scrappy;
use FindBin;
use Test::More $ENV{TEST_LIVE} ?
    (tests => 1) : (skip_all => 'env var TEST_LIVE not set, live testing is not enabled');

my  $s = Scrappy->new;
    $s->crawl('http://search.cpan.org/recent',
        '/recent' => {
            '#cpansearch li a' => sub {
                defined $_[0]->stash->{links} ?
                    push @{$_[0]->stash->{links}}, $_[1]->{href} :
                    $_[0]->stash('links' => [$_[1]->{href}]);
            }
        }
    );

ok  scalar @{$s->stash->{links}} > 0;