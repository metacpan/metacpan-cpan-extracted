#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;

unless ( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} ) {
    plan( skip_all => 'Author/Release tests not required for installation' );
}

eval 'use Test::Perl::Critic';
plan( skip_all => 'Test::Perl::Critic required for testing code quality' ) if $@;

sub find_rcfile {
    my $dir = File::Spec->rel2abs('.');
    for (1..5) {
        my $rc = File::Spec->catfile($dir, '.perlcriticrc');
        return $rc if -f $rc;
        $dir = File::Spec->catdir($dir, '..');
    }
    return '.perlcriticrc';
}

my $rcfile = find_rcfile();
if (-f $rcfile) {
    Test::Perl::Critic->import( -severity => 5, -profile => $rcfile );
} else {
    Test::Perl::Critic->import( -severity => 5 );
}

all_critic_ok('lib');
