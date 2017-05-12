use 5.006;
use utf8;
use strict;
use warnings;

use English qw{ −no_match_vars };

use Module::Build;


my $class;
my $builder;

$class = Module::Build->subclass( code => <<'SUBCLASS' );

    sub ACTION_authortest {
        my $self = shift;

        $self->depends_on('build');
        $self->depends_on('manifest');
        $self->depends_on('distmeta');
        $self->recursive_test_files(1);
        $self->depends_on('test');
    } # end ACTION_authortest()

    sub ACTION_distdir {
        my $self = shift;

        $self->depends_on('authortest');

        $self->SUPER::ACTION_distdir;
    } # end ACTION_distdir

SUBCLASS

$builder = $class->new(
    module_name        => 'Perl::Critic::Swift',
    license            => 'perl',
    dist_author        => 'Elliot Shank <perl@galumph.com>',
    dynamic_config     => 0,
    build_requires     => {
        'File::Spec'                => 0,
        'Perl::Critic::TestUtils'   => 1.082,
        'Test::Perl::Critic'        => 1.01,
        'English'                   => 0,
        'Test::More'                => 0,
    },
    requires           => {
        'base'                  => 0,
        'List::MoreUtils'       => 0.21,
        'Perl::Critic::Policy'  => 1.082,
        'Perl::Critic::Utils'   => 1.082,
        'strict'                => 0,
        'utf8'                  => 0,
        'version'               => 0,
        'warnings'              => 0,
    },
    meta_merge      => {
        configure_requires  => {
            'Module::Build' => 0.2808,
        },
    },
    create_packlist    => 1,
    sign               => 0,
    create_makefile_pl => 'passthrough',
    add_to_cleanup     => [
        qw{
            MANIFEST
            MANIFEST.bak
            META.yml
            Makefile
            Makefile.PL
            Perl-Critic-Swift-*
            *.vim_backup
            pod2htm?.tmp
        }
    ],
);


$builder->create_build_script();

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
