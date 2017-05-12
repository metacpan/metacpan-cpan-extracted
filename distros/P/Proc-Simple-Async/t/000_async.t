#!/usr/bin/env perl

use Test::More tests => 2;

use strict;
use warnings;

BEGIN { use_ok ('Proc::Simple::Async') };

isa_ok (async { 1 },'Proc::Simple');

