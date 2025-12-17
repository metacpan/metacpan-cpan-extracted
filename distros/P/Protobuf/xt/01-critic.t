#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Perl::Critic -exclude => ['ProhibitUselessNoCritic'];
use File::Find;

my @files;
find(sub {
    push @files, $File::Find::name if /\.pm$/ && -f $_;
}, 'lib/TSE');
push @files, glob "bin/**/*.pl t/**/*.t";
@files = grep { !m{t/broken/}x } @files;

plan tests => scalar @files;

foreach my $file (@files) {
    critic_ok( $file, "$file is critic clean" );
}
