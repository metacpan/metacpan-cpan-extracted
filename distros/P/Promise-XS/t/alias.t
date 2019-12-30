#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Promise::XS;

is(
    \&Promise::XS::Deferred::is_pending,
    \&Promise::XS::Deferred::is_in_progress,
    'is_in_progress() and is_pending() are the same',
);

done_testing;
