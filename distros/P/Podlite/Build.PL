use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Podlite',
    license            => 'perl',
    dist_author        => q{Aliaksandr Zahatski <zag@cpan.org>},
    dist_version_from  => 'lib/Podlite.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0.88',
        'File::Temp' => '0',
    },
    requires => {
        'perl'               => '5.010001',
        'Filter::Util::Call' => '0',
        'Carp'               => '0',
    },
    add_to_cleanup => ['Podlite-*'],
    meta_merge     => {
        'meta-spec' => { version => 2 },
        prereqs     => {
            develop => {
                requires => {
                    'Test::Pod'           => '1.22',
                    'Test::Pod::Coverage' => '1.10',
                    'Pod::Coverage'       => '0.18',
                    'Test::CheckManifest' => '0.9',
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/zag/p5-Podlite.git',
                web  => 'https://github.com/zag/p5-Podlite',
            },
            bugtracker => { web => 'https://github.com/zag/p5-Podlite/issues' },
        },
    },
);

$builder->create_build_script();
