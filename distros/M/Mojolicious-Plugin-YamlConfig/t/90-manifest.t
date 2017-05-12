use Test::More;

plan skip_all => 'author test' unless ($ENV{RELEASE_TESTING});

eval 'use Test::DistManifest; 1'
? manifest_ok()
: plan skip_all => 'Test::DistManifest required to test MANIFEST';
