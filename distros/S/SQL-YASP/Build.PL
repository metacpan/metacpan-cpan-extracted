use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'SQL::YASP - SQL parser and evaluater',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'SQL::YASP',
            'requires' => {
                            'Tie::IxHash' => 0
                          },
            'dist_version_from' => 'lib/SQL/YASP.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
