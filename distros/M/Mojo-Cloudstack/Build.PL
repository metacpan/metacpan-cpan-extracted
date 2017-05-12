use 5.10.1;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name        => 'Mojo::Cloudstack',
  license            => 'artistic_2',
  dist_abstract      => 'API Request and class generator for Apache Cloudstack',
  dist_author        => q{Holger Rupprecht <holger.rupprecht@gmx.de>},
  dist_version_from  => 'lib/Mojo/Cloudstack.pm',
  release_status     => 'stable',
  configure_requires => {
    'Module::Build' => 0,
  },
  build_requires => {
    'Test::CPAN::Changes' => 0,
    'Test::More'          => 0,
    'Test::Exception'     => 0,
    'Test::MockObject'    => 0,
  },
  requires => {
    'Mojolicious'       => 0,
    'URL::Encode'       => 0,
    'Digest::HMAC_SHA1' => '1.03',
    'URI::Encode'       => 0,
    'File::HomeDir'     => 0,
    'IO::Socket::SSL'   => '2.020',
  },
  add_to_cleanup     => ['Mojo-Cloudstack-*'],
  create_makefile_pl => 'traditional',
);

$builder->create_build_script();
