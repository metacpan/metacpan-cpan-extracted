use Pongo::CheckVersion;

my $minor_version = Pongo::CheckVersion::get_mongoc_minor_version();
print "MongoDB C Driver Minor Version: $minor_version\n";
