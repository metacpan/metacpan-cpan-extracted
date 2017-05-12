use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::XML',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/XML.pm',
    build_requires => {
        'Test::More'  => 0,
        'File::Slurp' => 0, #dep of Padre
    },
    requires => {
        'Padre'       => '0.65',
        'XML::Tidy'   => 1,
        'XML::LibXML' => '1.67',
    },
    add_to_cleanup      => [ 'Padre-Plugin-XML-*' ],
    create_makefile_pl  => 'traditional',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-XML/',
        }
    },
);

$builder->create_build_script();
