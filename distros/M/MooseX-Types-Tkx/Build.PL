use strict;
use warnings;
use Module::Build;
my $builder = Module::Build->new(
   module_name       => 'MooseX::Types::Tkx',
   license           => 'artistic2',
   dist_author       => 'Juergen von Brietzke <juergen.von.brietzke@t-online.de>',
   dist_version_from => 'lib/MooseX/Types/Tkx.pm',
   requires => {
      'perl'                 => 5.012000,
      'Scalar::Util'         => 0,
      'Modern::PBP::Perl'    => 1.200,
      'MooseX::Types'        => 0,
      'MooseX::Types::Moose' => 0,
   },
   build_requires => {
      'Test::More'          => 0,
      'Test::Pod'           => 1.14,
      'Test::Pod::Coverage' => 1.04,
   },
   configure_requires => { 'Module::Build' => 0.42 },
   add_to_cleanup     => [ 'MooseX-Types-Tkx-*' ],
);
$builder->create_build_script();
