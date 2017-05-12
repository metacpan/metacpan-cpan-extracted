use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Perlbal::Plugin::ExpandSSL',
    license             => 'perl',
    dist_author         => q{Sawyer X <xsawyerx@cpan.org>},
    dist_version_from   => 'lib/Perlbal/Plugin/ExpandSSL.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Warn' => 0,
    },
    requires => {
        'perl'         => 5.006,
        'Perlbal'      => 0,
        'Crypt::X509'  => 0,
        'MIME::Base64' => 0,
        'File::Slurp'  => 0,
    },
    add_to_cleanup      => [ 'Perlbal-Plugin-ExpandSSL-*' ],
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    create_license     => 1,
);

$builder->create_build_script();
