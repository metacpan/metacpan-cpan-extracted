use 5.006_001;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name       => 'String::LCSS_XS',
    dist_version_from => 'lib/String/LCSS_XS.pm',
    configure_requires => {
        'Module::Build' => 0.07,
    },
    requires          => {  
        'XSLoader'   => 0,
        'Exporter'   => 0,
        'perl'       => '5.8.0',
    },
    build_requires    => { 
        'Test::More' => 0, 
        'ExtUtils::CBuilder' => 0, 
    },
    dist_author       => 'Markus Riester <limaone@cpan.org>',
    license           => 'perl',
    c_source          => './',
    xs_files          => { 'LCSS_XS.xs' => 'lib/String/LCSS_XS.xs', },
    add_to_cleanup    => [ 'String-LCSS_XS-*', '*.o' ],
);

$build->create_build_script;
