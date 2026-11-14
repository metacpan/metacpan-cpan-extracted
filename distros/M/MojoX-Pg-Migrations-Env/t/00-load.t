#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use lib 'local/lib/perl5';

use Test2::Bundle::More;

use MojoX::Pg::Migrations::Env;

ok( 1, "All modules can be loaded" );

done_testing;
