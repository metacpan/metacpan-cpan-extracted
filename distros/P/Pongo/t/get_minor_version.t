use strict;
use warnings;
use Test::More tests => 1;
use Pongo::CheckVersion;

eval {
    my $minor_version = Pongo::CheckVersion::GetMongoMinorVersion();
    # Check if the minor version is defined and is a valid integer
    ok(defined($minor_version) && $minor_version =~ /^\d+$/, "Minor version is defined and a valid integer");
};
if ($@) {
    fail("Error while checking MongoDB Minor version: $@");
}
