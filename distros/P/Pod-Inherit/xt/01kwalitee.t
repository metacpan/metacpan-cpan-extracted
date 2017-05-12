#!/usr/bin/perl
use lib 't/auxlib';
use Test::JMM;
use warnings;
use strict;
use Test::More;

# We *do* test pod coverage, test::kwalitee gets it wrong, but test::kwalitee won't install for me,
# so I can't figure out why.
eval { require Test::Kwalitee; Test::Kwalitee->import( tests => ['-has_test_pod_coverage']) };

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
# don't add more tests to this file (they won't get run in the skip_all case;
# in the not skip-all case, the count will be wrong).
