#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 16;
use Perl::Critic;
use Perl::Critic::Config;
use Perl::Critic::TestUtils 'pcritique';

Perl::Critic::TestUtils::block_perlcriticrc();

my @a_tests = (
    { code => q{ my $i_foo = 12313; },                       violations => 0, comment => 'my integer ok' },
    { code => q{ my $s_bar = 'csacsa'; },                    violations => 0, comment => 'my string ok' },
    { code => q{ my $bar = (1); },                           violations => 1, comment => 'my array failing' },
    { code => q{ my $bar = undef; },                         violations => 1, comment => 'my undef failing' },
    { code => q! my $bar = do { qw(mares eat oats eat); } !, violations => 1, comment => 'my code ref failing' },
    { code => q{ local $bar = (1); },                        violations => 1, comment => 'local list failing' },
    { code => q{ local $ar_bar = []; },                      violations => 0, comment => 'local array ref ok' },
    { code => q{ our $bar = (1); },                          violations => 1, comment => 'global list failing' },
    { code => q{ our $ar_bar = []; },                        violations => 0, comment => 'global array ref ok' },
    { code => q{ our $f_bar = 1.123; },                      violations => 0, comment => 'global float ok' },
    { code => q{ my $f_bar = 1.123; },                       violations => 0, comment => 'my float ok' },
    {
        code => q{
        my $i_bar = shift;
        my $f_bar = 1.123;
        my $a_bar = 1.123;
        my $bar = 1.123;
        my $f_foo = 1.123;
        my $foo = 1.123;
        my $s_foo = '';
        my $fooBar = '';
     },
        violations => 4,
        comment    => 'multiple fails'
    },
    { code => q{ my $cr_bar = sub{return 1;} }, violations => 0, comment => 'my code ref ok' },
    { code => q{ my $bar = sub{return 1;} },    violations => 1, comment => 'my code ref failing' },
    { code => q{ state $bar = 1; },             violations => 1, comment => 'state integer failing' },
    { code => q{ state $i_bar = 2; },           violations => 0, comment => 'state integer ok' },
);

is( pcritique( 'Variables::RequireHungarianNotation', \$_->{code} ), $_->{violations}, $_->{comment} ) for @a_tests;

exit 0;

__END__
