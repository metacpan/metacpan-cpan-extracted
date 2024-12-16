use Pongo::CheckVersion;

my $micro_version = Pongo::CheckVersion::get_mongoc_micro_version();
print "MongoDB C Driver Micro Version: $micro_version\n";
