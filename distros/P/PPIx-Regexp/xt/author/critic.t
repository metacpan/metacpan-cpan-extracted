package main;

use strict;
use warnings;

use File::Spec;
use Test::More 0.88;

BEGIN {
    eval {
	require Test::Perl::Critic;
	Test::Perl::Critic->import(
	    -profile => File::Spec->catfile(qw{xt author perlcriticrc})
	);
	1;
    } or do {
	plan skip_all => 'Test::Perl::Critic required to criticize code.';
	exit;
    };
}

all_critic_ok();

1;
