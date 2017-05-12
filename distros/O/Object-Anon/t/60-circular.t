#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;
use Test::Exception;

use Object::Anon;

my $h = {};
$h->{foo} = $h;

throws_ok { anon $h } qr/circular reference detected/, 'circular reference detected';

done_testing;
