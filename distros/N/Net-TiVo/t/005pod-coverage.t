use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok({also_private => [qw(TIVO_MIME_TYPES new item_count item_start make_accessor make_array_accessor walk_hash_ref)]});
