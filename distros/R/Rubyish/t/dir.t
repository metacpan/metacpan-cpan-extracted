#!/usr/bin/env perl
use strict;

use Rubyish;

use Test::More;

plan tests => 1;

ok( Rubyish::Dir->pwd );

