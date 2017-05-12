#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

{
  ## no critic
  eval q(
    use Test::Strict;
    $Test::Strict::TEST_WARNINGS = 1;
  );
}

plan(skip_all => 'Test::Strict is required') if $@;
all_perl_files_ok(qw(lib t));
