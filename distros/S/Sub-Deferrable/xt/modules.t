#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;

eval "use Test::Module::Used";
plan skip_all => "Test::Module::Used required to test module usage" if $@;

my $used = Test::Module::Used->new();
$used->ok;
