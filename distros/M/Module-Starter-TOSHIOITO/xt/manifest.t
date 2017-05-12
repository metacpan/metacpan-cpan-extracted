use 5.006;
use strict;
use warnings;
use Test::More;
 
unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Set RELEASE_TESTING environment variable to test MANIFEST" );
}
 
my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;
 
ok_manifest();
