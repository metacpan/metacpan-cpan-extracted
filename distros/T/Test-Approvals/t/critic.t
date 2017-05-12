#! perl

use Modern::Perl '2012';
use strict;
use warnings FATAL => 'all';
use version; our $VERSION = qv('v0.0.5');

use English qw(-no_match_vars);
use Test::More;

## no critic (RequireCheckingReturnValueOfEval)
eval {
    require Test::Perl::Critic::Progressive;
    Test::Perl::Critic::Progressive::set_critic_args( -severity => 1 );
};
## use critic

if ($EVAL_ERROR) {
    plan skip_all => 'T::P::C::Progressive required for this test';
}
Test::Perl::Critic::Progressive::progressive_critic_ok();

