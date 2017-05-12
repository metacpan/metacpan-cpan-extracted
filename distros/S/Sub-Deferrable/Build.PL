use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass( code => <<'EOF' );

    sub ACTION_authortest {
        my ($self) = @_;

        $self->depends_on('build');
        $self->depends_on('manifest');
        $self->depends_on('distmeta');

        $self->test_files( qw< t xt/ > );
        $self->recursive_test_files(1);

        $self->depends_on('test');

        return;
    }

    sub ACTION_distdir {
        my ($self) = @_;

        $self->depends_on('authortest');

        return $self->SUPER::ACTION_distdir();
    }
EOF

my $builder = $class->new(
    module_name         => 'Sub::Deferrable',
    license             => 'perl',
    dist_author         => q{Len Budney <len.budney@grantstreet.com>},
    dist_version_from   => 'lib/Sub/Deferrable.pm',

    requires => {
        'perl'  => '5.008001',
    },

    build_requires => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },

    configure_requires => {
        'Module::Build' => 0.33,
    },

    add_to_cleanup      => [qw{
        *.bak
        Sub-Deferrable-*
    }],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
