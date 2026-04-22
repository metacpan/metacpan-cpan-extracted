# cpanm --installdeps .

# Core framework dependencies (always required)
requires 'Carp';
requires 'Data::Dumper';
requires 'Digest::SHA';
requires 'Exporter';
requires 'Hash::Merge';
requires 'Scalar::Util';
requires 'Storable', '2.34';

# Optional: only needed if using the corresponding mock model
recommends 'DBI';
recommends 'LWP::UserAgent';
recommends 'HTTP::Status';
recommends 'Path::Tiny', '0.144';
recommends 'URI';

# Test suite needs the optional modules
test_requires 'Test::Most';
test_requires 'DBI';
test_requires 'LWP::UserAgent';
test_requires 'HTTP::Status';
test_requires 'Path::Tiny', '0.144';
test_requires 'URI';
