use 5.006;
use strict;
use warnings;
use Module::Build;
use ExtUtils::PkgConfig;

#eval { require ExtUtils::PkgConfig; } or
#   die "OS unsupported - no ExtUtils::PkgConfig\n";

my %gnome_keyring_pkg_info;
eval {
    %gnome_keyring_pkg_info = ExtUtils::PkgConfig->find("gnome-keyring-1");
} or die "OS unsupported - need gnome-keyring development libraries\n$@";

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
    module_name         => 'Passwd::Keyring::Gnome',
    license             => 'perl',
    dynamic_config      => 1,

    needs_compiler => 1,
    extra_compiler_flags => $gnome_keyring_pkg_info{cflags},
    extra_linker_flags => $gnome_keyring_pkg_info{libs},

    build_requires => {
        'Module::Build' => '0.19', # xs
        'ExtUtils::CBuilder' => 0,
        'Test::More' => 0,
        'Test::Pod::Coverage' => '1.0',
        'Pod::Readme' => '1.001002',
        'Pod::Markdown' => '2.0',
    },
    configure_requires => {
        'Module::Build' => '0.36',
        'ExtUtils::PkgConfig' => '1.12',
    },
    requires => {
        'perl' => 5.006,
    },

    share_dir => {
        dist => [ 'example' ],
    },

    create_makefile_pl => 'small', # not 'traditional', we test for libraries in Build.pl
    add_to_cleanup      => [ 'Passwd-Keyring-Gnome-*' ],

    create_readme       => 1,
    dist_author         => q{Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>},
    dist_version_from   => 'lib/Passwd/Keyring/Gnome.pm',
    meta_merge => {
        keywords => [ qw/ passwords security secure-storage keyring GNOME seahorse gnome-keyring / ],
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-gnome',
            repository => 'https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-gnome',
            bugtracker => 'https://helixteamhub.cloud/mekk/projects/perl/issues',
        },
    },
);

$builder->create_build_script();
