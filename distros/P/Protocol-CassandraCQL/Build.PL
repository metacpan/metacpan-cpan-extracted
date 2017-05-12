use strict;
use warnings;

use Module::Build;

my %also_requires;

# If you don't support 64-bit pack formats natively you will need Math::Int64
eval { pack( "q>", 1 ) eq "\0\0\0\0\0\0\0\1" } or
   $also_requires{"Math::Int64"} = 0;

my $build = Module::Build->new(
   module_name => 'Protocol::CassandraCQL',
   requires => {
      'Compress::Snappy' => 0,
      'Encode' => 0,
      'Math::BigInt' => 0,
      'IO::Socket::IP' => 0,
      'Socket' => '1.82', # inet_pton
      %also_requires,
   },
   test_requires => {
      'Test::HexString' => 0,
      'Test::Fatal' => 0,
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   dynamic_config => 1,
   license => 'perl',
   create_makefile_pl => 'small', # since we do active testing here
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
