use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    dist_name           => 'Example-Dist',
    module_name         => 'Foo::Bar',
    dist_abstract       => 'Abstract goes here.',
    dist_author         => 'Jaldhar H. Vyas <jaldhar@braincells.com>',
    license             => 'perl',
    dist_version_from   => 'lib/Foo/Bar.pm',
    share_dir           => 'share',
    build_requires => {
        'Test::More'                    => 0,
        'Test::WWW::Mechanize::CGIApp'  => 0,
    },
    requires => {
        'perl'                          => 5.006,
        'CGI::Application'              => 4.04,
        'HTML::Template'                => 0,
    },
    add_to_cleanup      => [ 'Example-Dist-*' ],
    create_makefile_pl  => 'traditional',
    sign                => 1,
);

$builder->create_build_script();

