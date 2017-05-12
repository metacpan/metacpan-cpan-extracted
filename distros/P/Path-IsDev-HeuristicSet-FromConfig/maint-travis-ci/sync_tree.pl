#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Path::FindDev qw( find_dev );
my $root = find_dev('./');

chdir "$root";

sub git_subtree {
    system( 'git', 'subtree', @_ ) == 0 or die "Git subtree had nonzero exit";
}

my $travis = 'https://github.com/kentfredric/travis-scripts.git';
my $prefix = 'maint-travis-ci';

if ( not -d -e $root->child($prefix) ) {
    git_subtree( 'add', '--prefix=' . $prefix, $travis, 'master' );
}
else {
    git_subtree( 'pull', '-m', 'Synchronise git subtree maint-travis-ci', '--prefix=' . $prefix, $travis, 'master' );
}

