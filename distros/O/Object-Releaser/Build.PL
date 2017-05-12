use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Object::Releaser -- Remove properties from an object when the releaser goes out of scope.',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'Object::Releaser',
            'requires' => {},
            'dist_version_from' => 'lib/Object/Releaser.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
