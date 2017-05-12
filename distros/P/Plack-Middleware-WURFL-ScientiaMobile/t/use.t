#!/usr/bin/env perl
 
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;
 
BEGIN { use_ok 'Plack::Middleware::WURFL::ScientiaMobile' }
