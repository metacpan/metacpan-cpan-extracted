#!perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    eval { require Test::Pod::Coverage }
      or plan skip_all => "Test::Pod::Coverage required for this test";
}

use Test::Pod::Coverage;

# MooX::Cmd has no real subs to document (just import)
pod_coverage_ok('MooX::Cmd', {trustme => [qr/^import$/]});

# Role attributes are documented with =attr (rendered by PodWeaver at build time)
# From source tree, Test::Pod::Coverage can't see the woven POD,
# so we trust the attribute accessors and builder methods
pod_coverage_ok(
    'MooX::Cmd::Role',
    {
        trustme => [qr/^(command_|new_with_cmd|execute_return|_)/],
    }
);

pod_coverage_ok(
    'MooX::Cmd::Tester',
    {
        trustme => [qr/^(test_cmd|test_cmd_ok|result_class)$/],
    }
);

# Roles with no public API to document
pod_coverage_ok('MooX::Cmd::Role::AbbrevCmds');
pod_coverage_ok('MooX::Cmd::Role::ConfigFromFile');

done_testing;
