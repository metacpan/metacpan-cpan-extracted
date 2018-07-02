#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;
use Perl::Critic;
use Perl::Critic::Config;
use Perl::Critic::TestUtils 'pcritique';

Perl::Critic::TestUtils::block_perlcriticrc();

my @a_tests = (
    { code => q{ my %h_foo = (); },                          violations => 0, comment => 'my list ok' },
    { code => q{ my %h_bar = (); },                          violations => 0, comment => 'my list ok' },
    { code => q{ my %bar = (1); },                           violations => 1, comment => 'my list failing' },
    { code => q{ my %bar = qw(mares eat oats mares); },      violations => 1, comment => 'my list failing' },
    { code => q! my %bar = do { qw(mares eat oats eat); } !, violations => 1, comment => 'my list failing' },
    { code => q{ (my %h_foo = ()) },                         violations => 0, comment => 'my list ok' },
);

is( pcritique( 'Variables::RequireHungarianNotation', \$_->{code} ), $_->{violations}, $_->{comment} ) for @a_tests;
exit 0;

__END__
