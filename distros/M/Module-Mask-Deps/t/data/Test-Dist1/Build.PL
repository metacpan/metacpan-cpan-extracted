use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name => 'Test::Dist1',
    license     => 'perl',
    dist_author => 'Matt Lawrence <mattlaw@cpan.org>',
    requires => {
        'perl'  => '5.3.7',
        'Foo'   => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'passthrough',
)->create_build_script;
