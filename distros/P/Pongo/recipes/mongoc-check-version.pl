use Pongo::CheckVersion;

my $required_major = 1;
my $required_minor = 24;
my $required_micro = 1;

if (Pongo::CheckVersion::get_mongoc_check_version($required_major, $required_minor, $required_micro)) {
    print "MongoDB C Driver version is sufficient.\n";
} else {
    print "MongoDB C Driver version is insufficient.\n";
}
