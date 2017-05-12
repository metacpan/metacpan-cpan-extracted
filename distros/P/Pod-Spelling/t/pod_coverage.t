use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
    if $@;

eval "use Pod::Coverage 0.18";
plan skip_all => "Pod::Coverage 0.18 required for testing POD coverage"
    if $@;

pod_coverage_ok(
    'Pod::Spelling', { 
    also_private => [ qr/^new$/ ], 
});

pod_coverage_ok('Test::Pod::Spelling');

eval "require Text::Aspell";
pod_coverage_ok('Pod::Spelling::Aspell') if !$@;

eval "require Text::Ispell";
pod_coverage_ok('Pod::Spelling::Ispell') if !$@;

done_testing;
