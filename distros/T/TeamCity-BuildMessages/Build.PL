use 5.008004;
use utf8;

use strict;
use warnings;

use English qw< -no_match_vars >;

use Module::Build;


my $class = Module::Build->subclass( code => <<'END_SUBCLASS' );

    sub ACTION_test {
        my ($self) = @_;

        $self->depends_on('manifest');

        return $self->SUPER::ACTION_test();
    }

    sub ACTION_authortest {
        my ($self) = @_;

        $self->depends_on('build');
        $self->depends_on('manifest');
        $self->depends_on('distmeta');

        $self->test_files( qw< t xt/author > );
        $self->recursive_test_files(1);

        $self->depends_on('test');

        return;
    } # end ACTION_authortest()

    sub ACTION_distdir {
        my ($self) = @_;

        $self->depends_on('authortest');

        return $self->SUPER::ACTION_distdir();
    } # end ACTION_distdir

END_SUBCLASS

my $builder = $class->new(
    module_name         => 'TeamCity::BuildMessages',
    dist_author         => 'Elliot Shank <perl@galumph.com>',
    license             => 'perl',
    dynamic_config      => 0,
    create_license      => 1,
    create_readme       => 0,
    create_packlist     => 1,
    sign                => 0,

    requires            => {
        'autodie'           => 0,
        'Carp'              => 0,
        'Exporter'          => 5.58,
        'IO::Handle'        => 0,
        'Readonly'          => 1.03,
        'strict'            => 0,
        'utf8'              => 0,
        'version'           => 0.74,
        'warnings'          => 0,
    },

    build_requires      => {
        'Test::Exception'   => 0,
        'Test::More'        => 0.72,
    },

    recommends          => {
    },

    meta_merge          => {
        configure_requires  => {
            'Module::Build' => 0.2808,
        },
        no_index    => {
            file        => [
                qw<
                >
            ],
            directory   => [
                qw<
                    xt
                >
            ],
        },
    },

    script_files        => [ glob('bin/*') ],

    add_to_cleanup      => [
        qw<
            MANIFEST
            MANIFEST.bak
            META.yml
            Makefile
            Makefile.old
            Makefile.PL
            pod2htm?.tmp
            pm_to_blib
            *.tmp
            *.bak
            */*.tmp
            */*.bak
            */*/*.tmp
            */*/*.bak
            */*/*/*.tmp
            */*/*/*.bak
            */*/*/*/*.tmp
            */*/*/*/*.bak
            TeamCity-BuildMessages-*
        >
    ],
);


$builder->create_build_script();

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
