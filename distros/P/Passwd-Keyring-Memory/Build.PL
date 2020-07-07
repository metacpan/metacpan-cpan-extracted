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
    module_name         => 'Passwd::Keyring::Memory',
    license             => 'perl',
    dynamic_config      => 1,

    build_requires => {
        'Test::More' => 0,
        'Pod::Readme' => '1.001002',
        'Pod::Markdown' => '2.0',
    },
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'perl' => 5.006,
    },

    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'Passwd-Keyring-MemoryOnly-*' ],

    create_readme      => 1,
    dist_author         => q{Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>},
    dist_version_from   => 'lib/Passwd/Keyring/Memory.pm',
    meta_merge => {
        keywords => ['keyring', 'passwords' ],
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-memory',
            repository => 'https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-memory',
            bugtracker => 'https://helixteamhub.cloud/mekk/projects/perl/issues',
        },
    },
);

$builder->create_build_script();
