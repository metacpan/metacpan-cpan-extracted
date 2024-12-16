package Pongo::CheckVersion;
use strict;
use warnings;
require XSLoader;

XSLoader::load('Pongo::CheckVersion', $Pongo::VERSION);

sub GetMongoCheckVersion {
    my ($required_major, $required_minor, $required_micro) = @_;
    my $compatible = Pongo::CheckVersion::get_mongoc_check_version($required_major, $required_minor, $required_micro);
    return defined($compatible) && $compatible ? 1 : 0;
}

sub GetMongoMajorVersion {
    my $major = Pongo::CheckVersion::get_mongoc_major_version();
    return $major;
}

sub GetMongoMinorVersion {
    my $minor = Pongo::CheckVersion::get_mongoc_minor_version();
    return $minor;
}

sub GetMongoMicroVersion {
    my $micro = Pongo::CheckVersion::get_mongoc_micro_version();
    return $micro;
}

sub GetMongoVersion {
    my $version = Pongo::CheckVersion::get_mongoc_version();
    return $version;
}

1;