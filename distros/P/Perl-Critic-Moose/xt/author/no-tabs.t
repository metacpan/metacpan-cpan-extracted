use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Perl/Critic/Moose.pm',
    'lib/Perl/Critic/Policy/Moose/ProhibitDESTROYMethod.pm',
    'lib/Perl/Critic/Policy/Moose/ProhibitLazyBuild.pm',
    'lib/Perl/Critic/Policy/Moose/ProhibitMultipleWiths.pm',
    'lib/Perl/Critic/Policy/Moose/ProhibitNewMethod.pm',
    'lib/Perl/Critic/Policy/Moose/RequireCleanNamespace.pm',
    'lib/Perl/Critic/Policy/Moose/RequireMakeImmutable.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Moose/ProhibitDESTROYMethod.run',
    't/Moose/ProhibitLazyBuild.run',
    't/Moose/ProhibitMultipleWiths.run',
    't/Moose/ProhibitNewMethod.run',
    't/Moose/RequireCleanNamespace.run',
    't/Moose/RequireMakeImmutable.run',
    't/policies.t'
);

notabs_ok($_) foreach @files;
done_testing;
