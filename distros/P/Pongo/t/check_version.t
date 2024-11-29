use strict;
use warnings;
use Test::More tests => 2;
use Pongo::CheckVersion;

my $required_major = 1;
my $required_minor = 18;
my $required_micro = 0;

eval {
    my $version_match = Pongo::CheckVersion::GetMongoCheckVersion($required_major, $required_minor, $required_micro);
    if ($version_match) {
        ok(1, "MongoDB C driver version matches expected version");
    } else {
        ok(0, "MongoDB C driver version does not match expected version");
    }
};
if ($@) {
    fail("Error while checking MongoDB version: $@");
}

eval {
    my $wrong_major = 99;
    my $version_match = Pongo::CheckVersion::GetMongoCheckVersion($wrong_major, $required_minor, $required_micro);
    if (!$version_match) {
        ok(1, "MongoDB C driver version does not match incorrect version");
    } else {
        ok(0, "MongoDB C driver version matches incorrect version");
    }
};
if ($@) {
    fail("Error while checking incorrect MongoDB version: $@");
}
