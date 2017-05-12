use strict;
use warnings;
use Module::Build;

# Recommendations are OS-dependant
my %recommends;
if($^O eq 'darwin') {
    $recommends{'Passwd::Keyring::OSXKeychain'} = '0.10';
}
if($^O =~ /^MSWin/) {
    # TODO: windows keyrings
}

if($^O !~ /^(MSWin|dos|darwin)/) {
    $recommends{'Passwd::Keyring::Gnome'} = '0.30';
    $recommends{'Passwd::Keyring::KDEWallet'} = '0.20';
}

$recommends{'Passwd::Keyring::PWSafe3'} = '0.21';

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
    module_name         => 'Passwd::Keyring::Auto',
    license             => 'perl',
    dynamic_config      => 1,

    requires            => {
        'Passwd::Keyring::Memory' => '0.24',
        'perl' => '5.6.0',   # let's believe perlver
        'Config::Simple' => 0,
        'Moo' => '1.00100',  # to avoid errors on non-subroutine defaults
        'Config::Tiny' => 0,
        'File::HomeDir' => 0,
        'Path::Tiny' => 0,
        'namespace::clean' => 0,
        'Try::Tiny' => 0,
        'App::Cmd' => 0,
        'App::Cmd::Plugin::Prompt' => 0,
        'MooseX::Types::Perl' => 0,  # App::Cmd invention
    },
    build_requires => {
        'Test::More' => 0,
        'Passwd::Keyring::Memory' => '0.24',
        'Pod::Readme' => '1.001002',
        'Pod::Markdown' => '2.0',
    },
    configure_requires => {
        'Module::Build' => '0.36',
    },
    recommends => \%recommends,

    share_dir => {
        dist => [ 'example' ],
    },

    script_files => "bin",

    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'Passwd-Keyring-Auto-*' ],

    create_readme      => 1,
    dist_author         => q{Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>},
    dist_version_from   => 'lib/Passwd/Keyring/Auto.pm',
    meta_merge => {
        keywords => [ qw/ passwords security secure-storage keyring / ],
        resources => {
            license     => ['http://dev.perl.org/licenses/'],
            homepage    => 'http://bitbucket.org/Mekk/perl-keyring-auto',
            repository => 'http://bitbucket.org/Mekk/perl-keyring-auto',
            bugtracker => 'https://bitbucket.org/Mekk/perl-keyring-auto/issues',
        },
    },
    # distmeta  => 1,
);

$builder->create_build_script();
