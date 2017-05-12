#!perl

use 5.008;
use strict;
use warnings 'all';

use Test::More;
use Test::Requires 0.02;

# Only authors get to criticize code
plan skip_all => 'Set TEST_AUTHOR to enable this test'
	unless $ENV{'TEST_AUTHOR'} || -e 'inc/.author';

# Required modules for this test
test_requires 'File::Spec';
test_requires 'Test::Perl::Critic' => 1.01;

# Script directories to check
my @directories = grep { -d $_ }
	qw(bin/ ex/ examples/ scripts/);

if (!@directories) {
	plan skip_all => 'No script directories in distribution';
}

Test::Perl::Critic->import(
	'-profile' => File::Spec->catfile('xt', 'perlcriticrc'),
);

# Criticize code
all_critic_ok(@directories);

