#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan tests => 1;

require_ok ('Parallel::ForkManager::Scaled');

diag( "Testing Parallel::ForkManager::Scaled $Parallel::ForkManager::Scaled::VERSION, Perl $], $^X" );
