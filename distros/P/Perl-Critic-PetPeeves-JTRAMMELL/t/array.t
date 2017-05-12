#!perl

use strict;
use warnings;
use Test::More tests => 6;
use Perl::Critic;
use Perl::Critic::Config;
use Perl::Critic::Policy::Variables::ProhibitUselessInitialization;

# import common P::C testing tools
use lib 't/lib';
use PerlCriticTestUtils 'pcritique';
PerlCriticTestUtils::block_perlcriticrc();

my @tests = ( # [ code, violation count ]
    [ q{ my @foo = (); },                 1 ],
    [ q{ my @bar = (); },                 1 ],
    [ q{ my @bar = (1); },                0 ],
    [ q{ my @bar = qw(mares eat oats); }, 0 ],
    [ q! my @bar = do { qw(mares eat oats); } !, 0 ],
    [ q{ (my @foo = ()) },                1 ],
);

for (@tests) {
    my ($perl, $nviol) = @$_;
    my $policy = 'Variables::ProhibitUselessInitialization';
    is( pcritique($policy, \$perl), $nviol, $policy);
}

