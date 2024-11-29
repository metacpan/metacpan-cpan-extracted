use strict;
use warnings;
use Test::More tests => 1;
use Pongo::CheckVersion;

eval {
    my $mongo_version = Pongo::CheckVersion::GetMongoVersion();
    # Check if the version string is defined and matches the expected format
    ok(defined($mongo_version) && $mongo_version =~ /^\d+\.\d+\.\d+$/, "MongoDB version is defined and has the correct format (x.y.z)");
};
if ($@) {
    fail("Error while checking MongoDB version: $@");
}
