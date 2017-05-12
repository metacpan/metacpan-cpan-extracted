#!/usr/bin/perl

use strict;
use utf8;
use Test::More;
use Term::Spinner::Lite;

plan tests => 8;

my $s = Term::Spinner::Lite->new();
isa_ok($s, 'Term::Spinner::Lite', 'object created');

is($s->_spin_char_size, 4, "got 4 spin chars");

is_deeply($s->spin_chars, [ qw(- \ | /) ], "default spin_chars match");

is_deeply($s->spin_chars(['◑', '◒', '◐', '◓']), ['◑', '◒', '◐', '◓'], "utf8 spin chars match");

is($s->count, 0, "count is 0");

is($s->delay, 0, "delay defaults to 0");
is($s->delay(1000), 1000, "set delay to 1000 microsecs");

$s->next for 1 .. 10;
$s->done;

is($s->count, 10, "count is 10");
