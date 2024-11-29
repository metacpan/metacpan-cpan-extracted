use strict;
use warnings;
use Test::More tests => 1;
use Pongo::CheckVersion;

eval {
    my $micro_version = Pongo::CheckVersion::GetMongoMicroVersion();
    # Check if the micro version is defined and is a valid integer
    ok(defined($micro_version) && $micro_version =~ /^\d+$/, "Micro version is defined and a valid integer");
};
if ($@) {
    fail("Error while checking MongoDB Micro version: $@");
}
