use 5.006;
use strict;
use warnings;
use Module::Build;
use Module::Build::Prereqs::FromCPANfile;
 
Module::Build->new(
    module_name         => 'Module::Starter::TOSHIOITO',
    license             => 'perl',
    dist_author         => q{Toshio Ito <toshioito@cpan.org>},
    dist_version_from   => 'lib/Module/Starter/TOSHIOITO.pm',
    release_status      => 'stable',
    add_to_cleanup     => [ 'Module-Starter-TOSHIOITO-*' ],
    recursive_test_files => 1,
    dynamic_config => 1,
    (-d "share") ? (share_dir => "share") : (),
    
    mb_prereqs_from_cpanfile(),
    
    no_index => {
        directory => ["t", "xt", "eg", "inc", "share"],
        file => ['README.pod', 'README.md'],
    },
    meta_add => {
        'meta-spec' => {
            version => 2,
            url => 'https://metacpan.org/pod/CPAN::Meta::Spec',
        },
        resources => {
            bugtracker => {
                web => 'https://github.com/debug-ito/Module-Starter-TOSHIOITO/issues',
            },
            repository => {
                url => 'git://github.com/debug-ito/Module-Starter-TOSHIOITO.git',
                web => 'https://github.com/debug-ito/Module-Starter-TOSHIOITO',
            },
        }
    }
)->create_build_script();
