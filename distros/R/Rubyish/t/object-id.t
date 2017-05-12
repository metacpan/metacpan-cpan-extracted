#!/usr/bin/env perl

use strict;

use lib 't/lib';

use Rubyish;

use Test::More;
plan tests => 2;

my $a = Array([0..10]);

like $a->object_id, qr/^\d+$/, "object_id method";
like $a->__id__,    qr/^\d+$/, "__id__ method";

