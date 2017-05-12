# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Plack::Middleware::Image::Dummy',
    dist_author =>
      'Tasuku SUENAGA a.k.a. gunyarakun <tasuku-s-cpanATATtitech.ac>',
    license => 'perl',

    requires => {
        perl                        => '5.008005',
        'parent'                    => '0',
        'Imager'                    => '0.94',
        'Imager::File::GIF'         => '0.86',
        'Imager::File::PNG'         => '0.86',
        'Imager::File::JPEG'        => '0.85',
        'Plack::Builder'            => '0',
        'Plack::Middleware::Static' => '0',
    },
    configure_requires => {
        'Module::Build' => '0.38',
    },
    build_requires => {
        'Test::More'      => '0.98',
        'Test::Requires'  => '0',
        'Test::Exception' => '0',
        'Plack::Test'     => '0',
    },

    no_index => { 'directory' => [ 'inc', 'author' ] },

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
