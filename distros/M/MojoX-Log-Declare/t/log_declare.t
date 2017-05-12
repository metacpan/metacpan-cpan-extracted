#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

my $CLASS = 'MojoX::Log::Declare';

use_ok $CLASS;
new_ok $CLASS;

can_ok $CLASS, ('trace','debug','error','warn','info','log');

done_testing;
