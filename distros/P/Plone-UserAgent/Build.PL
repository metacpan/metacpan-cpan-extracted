use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new
    ( module_name        => 'Plone::UserAgent',
      license            => 'perl',
      requires           => { 'Config::INI'      => '0',
                              'File::HomeDir'    => '0',
                              'HTTP::Cookies'    => '0',
                              'LWP::UserAgent'   => '0',
                              'Moose'            => '0',
                              'MooseX::NonMoose' => '0',
                              'URI'              => '0',
                            },
      build_requires     => { 'Test::Exception' => '0',
                              'Test::More'      => '0',
                            },
      create_readme      => 1,
      sign               => 1,
      create_makefile_pl => 'traditional',
    );

$builder->create_build_script();
