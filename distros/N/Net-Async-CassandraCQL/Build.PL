use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::CassandraCQL',
   requires => {
      'Devel::GlobalDestruction' => 0,
      'Devel::Refcount' => 0,
      'Future' => '0.17', # immediate bugfixes
      'IO::Async::Loop' => '0.54', # ->connect returns Future
      'IO::Async::Stream' => '0.59',
      'IO::Socket::IP' => 0,
      'Protocol::CassandraCQL' => '0.11', # parse_results_frame v2 bugfix, ->has_metadata
   },
   build_requires => {
      'IO::Async::Test' => 0,
      'Test::HexString' => 0,
      'Test::Fatal' => 0,
      'Test::Identity' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   recommends => {
      'Compress::Snappy' => 0, # for CQL v1 compression
      'Compress::LZ4'    => 0, # for CQL v2 compression
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'small', # since we do active testing here
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
