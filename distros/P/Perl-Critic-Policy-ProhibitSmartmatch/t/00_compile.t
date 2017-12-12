use strict;
use Test::More;

use_ok $_ for qw(
    Perl::Critic::Policy::ControlStructures::ProhibitSwitchStatements
    Perl::Critic::Policy::Operators::ProhibitSmartmatch
);

done_testing;

