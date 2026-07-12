#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use_ok('Mojolicious::Plugin::Fondation::Asset');
can_ok('Mojolicious::Plugin::Fondation::Asset', 'VERSION');

done_testing;
