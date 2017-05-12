#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Try::Tiny;
use Test::More;

if (!$ENV{RUN_AUTHOR_TESTS} ) {
    plan( skip_all => 'Set $ENV{RUN_AUTHOR_TESTS} to a true value to run.' );
}

try {
    require Test::Perl::Critic;
} catch {
    plan(skip_all => 'Test::Perl::Critic not found.');
};

Test::Perl::Critic->import(-profile => 't/perlcriticrc');
all_critic_ok('lib');

