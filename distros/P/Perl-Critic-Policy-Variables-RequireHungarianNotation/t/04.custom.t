#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 5;
use Perl::Critic;
use Perl::Critic::Config;
use Perl::Critic::TestUtils 'pcritique';

Perl::Critic::TestUtils::block_perlcriticrc();

my @a_tests = (
    { code => q{ my $inv_foo = 12313; },                     violations => 0, comment => 'my integer ok' },
    { code => q{ my $obj_bar = 'csacsa'; },                  violations => 0, comment => 'my string ok' },
    { code => q{ my $bar = (1); },                           violations => 1, comment => 'my array failing' },
    { code => q{ my $bar = undef; },                         violations => 1, comment => 'my undef failing' },
    { code => q! my $bar = do { qw(mares eat oats eat); } !, violations => 1, comment => 'my code ref failing' },
);

is( pcritique( 'Variables::RequireHungarianNotation', \$_->{code}, { custom => 'inv obj' } ),
    $_->{violations}, $_->{comment} )
  for @a_tests;

exit 0;

__END__
