#!/usr/bin/perl

use strict;
use warnings;
use v5.10;

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok('Mojolicious::Plugin::AnyData') || say "Bail out!";
}

done_testing();
