use 5.006;
use strict;
use warnings;
use Module::Build;
 
my $builder = Module::Build->new(
    module_name         => 'Module::Build::Prereqs::FromCPANfile',
    license             => 'perl',
    dist_author         => q{Toshio Ito <toshioito@cpan.org>},
    dist_version_from   => 'lib/Module/Build/Prereqs/FromCPANfile.pm',
    release_status      => 'stable',
    add_to_cleanup     => [ 'Module-Build-Prereqs-FromCPANfile-*' ],
    recursive_test_files => 1,
    no_index => {
        directory => ["t", "xt", "eg", "inc"],
        file => ['README.pod'],
    },
    requires => {
        "Module::CPANfile" => "1.0000",
        'Exporter' => "0",
        'version' => "0.80",
        'CPAN::Meta::Prereqs' => '2.132830',
    },
    recommends => {
        "Module::Build" => "0.4004",
    },
    test_requires => {
        'Test::More' => "0",
    },
    meta_add => {
        'meta-spec' => {
            version => 2,
            url => 'https://metacpan.org/pod/CPAN::Meta::Spec',
        },
        resources => {
            bugtracker => {
                web => 'https://github.com/debug-ito/Module-Build-Prereqs-FromCPANfile/issues',
            },
            repository => {
                url => 'git://github.com/debug-ito/Module-Build-Prereqs-FromCPANfile.git',
                web => 'https://github.com/debug-ito/Module-Build-Prereqs-FromCPANfile',
            },
        }
    }
);
 
$builder->create_build_script();
