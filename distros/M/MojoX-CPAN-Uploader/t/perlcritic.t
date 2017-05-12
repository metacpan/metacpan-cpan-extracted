#!perl

use strict;
use warnings;

use Test::More;
use File::Spec;

eval { require Test::Perl::Critic; };

if ($@) {
    plan(
        skip_all => 'Test::Perl::Critic required for testing PBP compliance');
}

my @config = ();    # Arguments for Perl::Critic->new() go here!
my $rcfile = File::Spec->catfile('t', 'perlcriticrc');

if (-f $rcfile) {
    push @config, -profile => $rcfile;
}

Test::Perl::Critic->import(@config);

all_critic_ok();
