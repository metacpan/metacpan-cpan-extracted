use 5.006;
use strict;
use warnings;
use Module::Build;

# Generate also README.md
# Testing: ./Build.PL; ./Build distmeta
# (alternatively we could override ACTION_distmeta, but this seems nicer)
my $class = Module::Build->subclass(
    class => 'MEKK::Module::Build',
    code => q{
        sub do_create_readme {
            my $self = shift;
            $self->SUPER::do_create_readme;  # Default
            my $docfile = $self->_main_docfile or return;  # Warning already emitted
            require Pod::Readme; require Pod::Markdown;
            $self->log_info("Creating README.md\n");
            my $parser = Pod::Readme->new(
                input_file => $docfile,
                translate_to_file => 'README.md',
                translation_class => 'Pod::Markdown');
            $parser->run;
            $self->_add_to_manifest('MANIFEST', 'README.md');
        }
    }
   );

my $builder = $class->new(
    module_name         => 'Passwd::Keyring::KDEWallet',
    license             => 'perl',
    dynamic_config      => 1,

    build_requires => {
        'Module::Build' => '0.19', # xs
        'Test::More' => 0,
        'Test::Pod::Coverage' => '1.0',
        'Pod::Readme' => '1.001002',
        'Pod::Markdown' => '2.0',
    },
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'perl' => 5.006,
        'Net::DBus' => 0,
        'Try::Tiny' => 0,
        'Proc::SyncExec' => 1.01,
    },

    share_dir => {
        dist => [ 'example' ],
    },

    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'Passwd-Keyring-KDEWallet-*' ],

    create_readme       => 1,
    dist_author         => q{Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>},
    dist_version_from   => 'lib/Passwd/Keyring/KDEWallet.pm',
    meta_merge => {
        keywords => [ qw/ passwords security secure-storage keyring KDE KDEWallet / ],
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-kdewallet',
            repository => 'https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-kdewallet',
            bugtracker => 'https://helixteamhub.cloud/mekk/projects/perl/issues',
        },
    },
);

$builder->create_build_script();
