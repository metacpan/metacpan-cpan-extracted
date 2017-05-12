#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Try::Tiny;
use Test::More;

if (!$ENV{RUN_AUTHOR_TESTS} ) {
    plan( skip_all => 'Set $ENV{RUN_AUTHOR_TESTS} to a true value to run.' );
}

try {
    require Test::NoTabs
} catch {
    plan(skip_all => 'Test::NoTabs not found.');
};

Test::NoTabs->import();
all_perl_files_ok(qw(lib t));

