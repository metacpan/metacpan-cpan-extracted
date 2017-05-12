use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Number::Misc - handy utilities for numbers',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'Number::Misc',
            'requires' => {},
            'dist_version_from' => 'lib/Number/Misc.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
