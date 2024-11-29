use strict;
use warnings;
use Test::More tests => 1;
use Pongo::CheckVersion;

eval {
    my $major_version = Pongo::CheckVersion::GetMongoMajorVersion();
    # Check if the major version is defined and is a valid integer
    ok(defined($major_version) && $major_version =~ /^\d+$/, "Major version is defined and a valid integer");
};
if ($@) {
    fail("Error while checking MongoDB major version: $@");
}
