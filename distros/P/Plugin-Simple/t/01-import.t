#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Plugin::Simple;

is (exists &plugins, 1, "by default, we get plugins() installed");

use Plugin::Simple sub_name => 'testing';

is (exists &testing, 1, "with sub_name arg, we get proper name");

done_testing();

