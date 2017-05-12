#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 11;

use_ok('Sword');

my $library = Sword::Manager->new;
my $calvin = $library->get_module('Institutes');

SKIP: {
    skip 'Institutes is not installed', 3 unless $calvin;

    my $key = $calvin->create_key;
    $calvin->set_key($key);
    $key->top;

    $calvin->set_key($key);
    is($key->index, 0, 'index at 0');
    is($key->get_text, '', 'top is not named');

    $key->increment;
    is($key->index, 4, 'index at 4 after increment');
    is($key->get_text, '/Title Page', 'next is title page');

    $key->decrement;
    is($key->index, 0, 'index at 0 after decrement');
    is($key->get_text, '', 'back to top is not named');

    $key->bottom;
    is($key->index, 424, 'index at 424 after bottom');
    is($key->get_text, '/ONE HUNDRED APHORISMS,/BOOK 4', 'bottom is book 4');

    ok(!$key->equals($calvin->get_key), 'key does not match module key');
    $calvin->set_key($key);
    ok($key->equals($calvin->get_key), 'key matches module key now');
}
