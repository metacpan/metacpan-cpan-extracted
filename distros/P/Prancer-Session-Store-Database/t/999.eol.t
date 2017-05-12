#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Try::Tiny;
use Test::More;

if (!$ENV{RUN_AUTHOR_TESTS} ) {
    plan( skip_all => 'Set $ENV{RUN_AUTHOR_TESTS} to a true value to run.' );
}

try {
    require Test::EOL;
} catch {
    plan(skip_all => 'Test::EOL not found.');
};

Test::EOL->import();
all_perl_files_ok({ trailing_whitespace => 1, all_reasons => 1 }, qw(lib t));

