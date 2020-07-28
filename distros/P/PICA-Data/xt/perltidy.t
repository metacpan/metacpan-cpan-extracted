use strict;
use warnings;

use Test::More;

## no critic
eval 'use Test::Code::TidyAll 0.20';
plan skip_all =>
    "Test::Code::TidyAll 0.20 required to check if the code is clean."
    if $@;

plan skip_all => "Incosistent behaviour of TidyAll depending on environment";

tidyall_ok();
