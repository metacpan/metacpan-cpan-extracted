use Pongo::CheckVersion;

my $major_version = Pongo::CheckVersion::get_mongoc_major_version();
print "MongoDB C Driver Major Version: $major_version\n";
