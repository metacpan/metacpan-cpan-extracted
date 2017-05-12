use strict;
use Module::Build;
my ($build, $params);


$params = {
            'module_name' => 'String::Util',
            'license' => 'perl',
            'dist_abstract' => 'String::Util -- String processing utilities',
            'requires' => {
                            'Test::Toolbox' => '0.2',
                            'Number::Misc' => '1.2'
                          },
            'dist_version_from' => 'lib/String/Util.pm',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
