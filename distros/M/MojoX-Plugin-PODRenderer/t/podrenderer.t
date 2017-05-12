#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

my $CLASS = 'MojoX::Plugin::PODRenderer';

use_ok $CLASS;
new_ok $CLASS;

done_testing;
