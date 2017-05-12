use strict;
use warnings;

use Module::Build;

my $builder =
    Module::Build->new
        ( module_name        => 'Template::Iterator::AlzaboWrapperCursor',
          license            => 'perl',
          requires           => { 'Class::AlzaboWrapper' => 0,
                                  'Test::More' => 0,
                                  'Template'   => 2,
                                },
          create_makefile_pl => 'passthrough',
          create_readme      => 1,
          sign               => 1,
        );

$builder->create_build_script();
