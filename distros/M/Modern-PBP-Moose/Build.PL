use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
   module_name         => 'Modern::PBP::Moose',
   license             => 'artistic2',
   dist_author         => 'Juergen von Brietzke <juergen.von.brietzke@t-online.de>',
   dist_version_from   => 'lib/Modern/PBP/Moose.pm',
   requires => {
      'perl'                                 => 5.012000,
      'Hook::AfterRuntime'                   => 0,
      'Modern::PBP::Perl'                    => 0,
      'Moose'                                => 0,
      'Moose::Exporter'                      => 0,
      'Moose::Util::TypeConstraints'         => 0,
      'MooseX::AttributeShortcuts'           => 0,
      'MooseX::DeclareX'                     => 0,
      'MooseX::DeclareX::Keyword::interface' => 0,
      'MooseX::DeclareX::Plugin::abstract'   => 0,
      'MooseX::DeclareX::Plugin::singleton'  => 0,
      'MooseX::DeclareX::Privacy'            => 0,
      'MooseX::HasDefaults::RO'              => 0,
      'namespace::autoclean'                 => 0,
   },
    build_requires => {
        'Test::More'          => 0,
        'Test::Perl::Critic'  => 0,
        'Test::Pod'           => 1.14,
        'Test::Pod::Coverage' => 1.04,
    },
   add_to_cleanup      => [ 'Modern-PBP-Moose-*' ],
);

$builder->create_build_script();
