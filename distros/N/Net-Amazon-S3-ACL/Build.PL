use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
   module_name       => 'Net::Amazon::S3::ACL',
   license           => 'perl',
   dist_author       => 'Flavio Poletti <flavio [at] polettix [dot] it>',
   dist_version_from => 'lib/Net/Amazon/S3/ACL.pm',
   requires          => {
      'Test::More'                => 0,
      'version'                   => 0,
      'Class::Accessor::Fast'     => 0,
      'XML::LibXML'               => 0,
      'XML::LibXML::XPathContext' => 0,
   },
   add_to_cleanup => ['Net-Amazon-S3-ACL-*'],
);

$builder->create_build_script();
