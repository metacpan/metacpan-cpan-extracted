#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $pkg = 'Plack::Session::Store::Catmandu';

require_ok $pkg;

isa_ok $pkg, 'Plack::Session::Store';

done_testing;
