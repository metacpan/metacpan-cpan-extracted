use 5.006;
use strict;
use warnings;
use Test::More;
 
use Test::CheckManifest;

unless($ENV{RELEASE_TESTING}) {
    plan(skip_all => "Set RELEASE_TESTING environment variable to test MANIFEST");
}
 
ok_manifest();
done_testing;
