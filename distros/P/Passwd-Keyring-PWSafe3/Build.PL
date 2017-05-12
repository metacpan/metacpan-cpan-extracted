use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Passwd::Keyring::PWSafe3',
    license             => 'perl',
    dynamic_config      => 1,

    build_requires => {
        'Module::Build' => '0.36',
        'Test::More' => 0,
        'Test::Pod::Coverage' => '1.0',
        'Pod::Readme' => 0,
    },
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'perl' => 5.009002, # pack(W) in Crypt::PWSafe3, http://search.cpan.org/~rgarcia/perl-5.9.2/pod/perl592delta.pod#Packing_and_UTF-8_strings
        'Crypt::PWSafe3' => '1.15', # 1.07 fixes huge performance problems, 1.11 fixes pack errors reported when password expire is set (I have such in my tests) but has quirks fixed in 1.12, 1.15 fixes corner-case tempfile problems
        'Bytes::Random::Secure' => '0.09', # performance fix works only when this module is present, without it PWSafe3 is very slow
        'Term::ReadKey' => 0, # for interactive password prompts
        'File::HomeDir' => 0,
    },
    recommends => {
        'Math::Random::ISAAC::XS' => 0,  # makes Bytes::Random::Secure faster
    },

    share_dir => {
        dist => [ 'example' ],
    },

    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'Passwd-Keyring-PWSafe3-*' ],

    create_readme       => 1,
    dist_author         => q{Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>},
    dist_version_from   => 'lib/Passwd/Keyring/PWSafe3.pm',
    meta_merge => {
        keywords => [ qw/ passwords security secure-storage keyring KDE PWSafe3 / ],
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'http://bitbucket.org/Mekk/perl-keyring-pwsafe3',
            repository => 'http://bitbucket.org/Mekk/perl-keyring-pwsafe3',
            bugtracker => 'https://bitbucket.org/Mekk/perl-keyring-pwsafe3/issues',
        },
    },
);

$builder->create_build_script();
