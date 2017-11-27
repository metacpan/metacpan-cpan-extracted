use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'SVG::Calendar',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/SVG/Calendar.pm',
    requires          => {
        'perl'                       => '5.010',
        'Clone'                      => '0.17',
        'Config::Std'                => 0,
        'DateTime::Format::Strptime' => 0,
        'File::ShareDir'             => '1.102',
        'Image::ExifTool'            => '7.0',
        'Math::Trig'                 => '1.15',
        'Path::Tiny'                 => '0.061',
        'Readonly'                   => '1.03',
        'Scalar::Util'               => 0,
        'Template'                   => '2.14',
        'version'                    => '0.74',
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    recommends => {
        'Astro::Coord::ECI::Moon' => 0.044,
        'Astro::MoonPhase'        => 0.60,
        'Test::Spelling'          => 0,
        'Test::Perl::Critic'      => 0,
        'Test::Kwalitee'          => 0,
        'Pod::Coverage'           => 0,
    },
    share_dir => {
        dist => [
            'templates',
        ],
    },
    add_to_cleanup     => [ 'SVG-Calendar-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'git://github.com/ivanwills/SVG-Calendar.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVG-Calendar',
        },
    },
);

$builder->create_build_script();
