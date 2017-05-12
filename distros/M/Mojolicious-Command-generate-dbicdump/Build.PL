use 5.006;
use strict;
use warnings;
use Module::Build;

# Use Build.PL for author dist-tools
# - use Makefile.PL to install
#
#   perl Build.PL 
#   ./Build             # builds README
#   ./Build manifest    # updates MANIFEST
#   ./Build dist        # generates new tarball
#

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code => q{
        sub ACTION_dist {
            use Pod::Readme;
            use Pod::Select;

            my $self = shift;

            podselect({ -output => 'README.pod' }, 'lib/Mojolicious/Command/generate/dbicdump.pm');

            my $parser = Pod::Readme->new();
            $parser->parse_from_file('README.pod', 'README');
            unlink 'README.pod';
            $self->log_info("Creating README from pod\n");
            return $self->SUPER::ACTION_dist;
        }
    }
);

my $builder = $class->new(
    module_name         => 'Mojolicious::Command::generate::dbicdump',
    license             => 'perl',
    dist_author         => q{Alister West <alister@alisterwest.com>},
    dist_version_from   => 'lib/Mojolicious/Command/generate/dbicdump.pm',
    build_requires => {
        'Test::More' => 0,
    },
    configure_requires => {
        'Module::Build' => 0,
    },
    recommends => {
        'Pod::Readme' => 0,
        'Pod::Select' => 0,
    },
    requires => {
        'perl' => 5.006,
        'DBIx::Class::Schema::Loader' => 0,
    },
    add_to_cleanup => [qw/
        Mojolicious-Command-generate-dbicdump-*
        blib
        MYMETA.*
        MANIFEST.*
    /],

    create_makefile_pl => 'traditional',
);


$builder->create_build_script();

