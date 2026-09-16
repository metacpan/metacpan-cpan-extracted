use strict;
use warnings;

use Test::More;

# Compile every class in the (post-diet) distribution. Auditor and the
# CLI command classes were removed in 2.0.0; MetaCPAN::Client, Moo, and
# the Type::Tiny stack are gone. This test is the canary that every
# surviving module still loads on the leaner dependency set.

use_ok $_ for qw(
    OrePAN2
    OrePAN2::Lite
    OrePAN2::Index
    OrePAN2::Indexer
    OrePAN2::Injector
    OrePAN2::Logger
    OrePAN2::Repository
    OrePAN2::Repository::Cache
    OrePAN2::Role::HasLogger
);

done_testing;
