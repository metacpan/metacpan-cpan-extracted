use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::CGI::Multipart',
    license             => 'perl',
    dist_author         => 'Nicholas Bamber <nicholas@periapt.co.uk>',
    dist_version_from   => 'lib/Test/CGI/Multipart.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'Perl6::Slurp'=>0,
    },
    requires => {
        'perl'=>'5.6.1',
        'MIME::Entity'=>0,
        'autodie'=>0,
        'version'    => 0,
        'UNIVERSAL::require' => 0,
        'CGI'   => '3.41',
        'Readonly' => 0,
        'Params::Validate'=>0,
    },
    recommends => {
        'Text::Lorem' => 0,
        'GD'=>0,
    },
    meta_merge => {
        resources => {
            repository =>
                'http://github.com/periapt/Test-CGI-Multipart/tree',
        },
        keywords => [ 'Test', 'CGI', 'upload', 'image', 'multipart/form-data' ],
    },
    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'Test-CGI-Multipart-*' ],
);

$builder->create_build_script();
