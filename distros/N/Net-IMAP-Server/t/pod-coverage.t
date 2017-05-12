#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my @modules
    = grep { not /^Net::IMAP::Server::Command::/ } Test::Pod::Coverage::all_modules();
plan( tests => scalar @modules );

pod_coverage_ok(
    $_,
    "Pod coverage on $_"
) for @modules;
