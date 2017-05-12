use ExtUtils::MakeMaker;
#DOC_FILES: StoredHash.pod storedhash_tutorial.pod
#require 5.6; # How to say this

WriteMakefile(
  'NAME'	 => 'StoredHash',
  'VERSION_FROM' => 'StoredHash.pm', # finds $VERSION
  'ABSTRACT'	 => 'Easy Insert, Update, Load and Delete of a DB (DBI) Stored Hash',
  'AUTHOR'	 => 'Olli Hollmen',
  # Class name => ver
  'PREREQ_PM'	 => {
      'DBI' => 1.40,
      'Data::Dumper' => 2.121,
      'Scalar::Util' => 0,
      # Build / testing requires ...
      'Test::More' => 0,
      'Storable' => 0,
      # Recommended
      #'DBI' => 0, # libdbi-perl
      #'DBD::SQLite' => 0, # libdbd-sqlite3-perl
      #'Test::Pod' => 0, # libtest-pod-perl
      #'DBD::CSV' => 0, # libdbd-csv-perl
      #'Net::LDAP' => 0, # libnet-ldap-perl
      #'ARS' => 0, # No debian pkg
      #'LWP' => 0, # libwww-perl (Next releases, REST NoSQL)
      #'MongoDB' => 0, # Use > new API ~ > 0.6 or > 0.7 (not old deb pkg)
  }
);
