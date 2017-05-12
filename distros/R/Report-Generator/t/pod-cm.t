#!perl

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Spelling::CommonMistakes qw(all_pod_files_ok)";
plan skip_all => "Test::Pod::Spelling::CommonMistakes required for testing POD spelling" if $@;

all_pod_files_ok();

1;
