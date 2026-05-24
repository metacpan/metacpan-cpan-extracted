#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# Build the exclusion list from the spec file explicitly, rather than
# walking the runtime stash with a heuristic. This ensures a future public
# helper without POD is caught instead of silently excluded.
BEGIN { $ENV{OPENAI_API_KEY} //= 'test-key' }
use OpenAPI::Client::OpenAI;
use OpenAPI::Client::OpenAI::Naming qw(to_snake_case);
use File::Spec::Functions qw(catfile);

my $spec_path = catfile( 'share', 'openapi.yaml' );
my $ops = OpenAPI::Client::OpenAI::_operation_ids_from_spec_file($spec_path);

# Keep only those operationIds whose snake_case form differs from the original
# (i.e. the ones for which an alias was actually installed).
my @snake_aliases =
    grep { to_snake_case($_) ne $_ }
    @$ops;
my @snake_names = map { to_snake_case($_) } @snake_aliases;

all_pod_coverage_ok(
    {
        also_private => [
            ( map { my $n = $_; qr/^\Q$n\E\z/ } @snake_names ),
            qr/^_/,     # private helpers
        ],
    }
);
