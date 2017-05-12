#!/usr/bin/env perl

use Scrappy;
use FindBin;
use Test::More $ENV{TEST_LIVE} ?
    (tests => 12) : (skip_all => 'env var TEST_LIVE not set, live testing is not enabled');

my  $s = Scrappy->new;
ok  $s->control->allow('http://search.cpan.org/');
ok  'HASH' eq ref $s->control->allowed->{'search.cpan.org'};
ok  $s->control->is_allowed('http://search.cpan.org/');
ok  $s->control->is_allowed('http://search.cpan.org/recent');
ok  $s->control->is_allowed('http://search.cpan.org/dist/Scrappy/lib/Scrappy.pm');
ok  ! $s->control->is_allowed('http://www.google.com/');
ok  0 == keys %{$s->control->restricted}; # no restriction rules set
ok  $s->control->restrict('search.cpan.org');
ok  ! $s->control->is_allowed('http://search.cpan.org/');
ok  ! $s->control->is_allowed('http://search.cpan.org/recent');
ok  ! $s->control->is_allowed('http://search.cpan.org/dist/Scrappy/lib/Scrappy.pm');
ok  $s->control->is_allowed('http://www.google.com/');
