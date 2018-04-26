#!/usr/bin/env perl

use strict;
use warnings;

use String::Compare::ConstantTime qw/equals/;

use Test::More tests => 2;

ok equals substr( "asdfg", 0, 4 ), "asdf";
ok equals "asdf", substr( "asdfg", 0, 4 );
