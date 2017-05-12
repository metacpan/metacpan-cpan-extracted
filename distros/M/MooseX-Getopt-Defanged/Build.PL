use 5.010;

use strict;
use warnings;

use Module::Build 0.33;


my $class = Module::Build->subclass( code => <<'END_SUBCLASS' );

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
    module_name         => 'MooseX::Getopt::Defanged',
    dist_author         => 'Elliot Shank <perl@galumph.com>',
    license             => 'bsd',
    dynamic_config      => 0,
    create_license      => 1,
    create_readme       => 0,
    create_packlist     => 1,
    sign                => 0,

    requires            => {
        'autodie'                             => 0,
        'English'                             => 0,
        'Exception::Class'                    => 0,
        'Exporter'                            => 0,
        'Getopt::Long'                        => 0,
        'Moose'                               => 0.92,
        'Moose::Role'                         => 0.92,
        'Moose::Util::TypeConstraints'        => 0.92,
        'MooseX::Accessors::ReadWritePrivate' => 0,
        'MooseX::AttributeHelpers'            => 0.2,
        'MooseX::StrictConstructor'           => 0.08,
        'Readonly'                            => 0,
        'Scalar::Util'                        => 0,
        'strict'                              => 0,
        'utf8'                                => 0,
        'version'                             => 0,
        'warnings'                            => 0,
    },

    build_requires      => {
        'Carp'                  => 0,
        'File::Spec::Functions' => 0,
        'lib'                   => 0,
        'overload'              => 0,
        'parent'                => 0,
        'Test::Class'           => 0,
        'Test::Compile'         => 0,
        'Test::Deep'            => 0,
        'Test::Exception'       => 0,
        'Test::Moose'           => 0,
        'Test::More'            => 0.88,
    },

    recommends          => {
        'Readonly::XS' => 0,
    },

    configure_requires  => {
        'Module::Build' => 0.33,
    },

    meta_merge          => {
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

    add_to_cleanup      => [
        qw<
            LICENSE
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
            MooseX-Getopt-Defanged-*
        >
    ],
);


$builder->create_build_script();


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :
