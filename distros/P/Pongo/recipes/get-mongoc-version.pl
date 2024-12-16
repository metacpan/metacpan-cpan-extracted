use Pongo::CheckVersion;

my $version = Pongo::CheckVersion::get_mongoc_version();
print "MongoDB C Driver Version: $version\n";
