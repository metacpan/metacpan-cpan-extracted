use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
   module_name       => 'Net::Amazon::S3::Policy',
   license           => 'perl',
   dist_author       => 'Flavio Poletti <flavio [at] polettix [dot] it>',
   dist_version_from => 'lib/Net/Amazon/S3/Policy.pm',
   requires          => {
      'Test::More' => 0,
      'version'    => 0,
      'JSON'       => '2.0',
      'perl'       => '5.8.0',
   },
   add_to_cleanup => ['Net-Amazon-S3-Policy-*'],
);

$builder->create_build_script();
