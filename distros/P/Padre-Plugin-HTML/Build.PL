use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::HTML',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/HTML.pm',
    build_requires => {
        'Test::More' => 0,
        'Padre' => '0.26',
        'XML::XPath' => 0,
        'WebService::Validator::HTML::W3C' => 0,
        'HTML::Tidy' => 0,
        'HTML::Lint' => 0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-HTML-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-HTML/',
        }
    },
);

$builder->create_build_script();
