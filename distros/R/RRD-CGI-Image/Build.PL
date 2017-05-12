use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'RRD::CGI::Image',
    license             => 'perl',
    dist_author         => 'Joshua Keroes <joshua@cpan.org>',
    dist_version_from   => 'lib/RRD/CGI/Image.pm',
    build_requires => {
        'Test::More' => 0,
		'Spiffy' => 0,
		'RRDs' => 0,
		'URI::Escape' => 0,
		'HTML::Entities' => 0,
    },
    add_to_cleanup      => [ 'RRD-CGI-Image-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
