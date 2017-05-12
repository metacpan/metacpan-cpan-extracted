use strict;
use warnings;

require 5.00601;

use Module::Build;

my $builder = Module::Build->new
    ( module_name        => 'MooseX::Policy::SemiAffordanceAccessor',
      license            => 'perl',
      requires           => { 'Moose'         => 0,
                              'Moose::Policy' => 0,
                            },
      build_requires     => { 'Test::More' => 0,
                            },
      create_makefile_pl => 'passthrough',
      create_readme      => 1,
      sign               => 1,
    );

$builder->create_build_script();
