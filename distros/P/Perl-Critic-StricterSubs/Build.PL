
use 5.006001;

use strict;
use warnings;

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
    }

    sub ACTION_distdir {
        my ($self) = @_;

        $self->depends_on('authortest');

        return $self->SUPER::ACTION_distdir();
    }

END_SUBCLASS

my $builder = $class->new(
    module_name     => 'Perl::Critic::StricterSubs',
    dist_author     => 'Jeffrey Thalhammer <thaljef@cpan.org>',
    dist_abstract   => 'Perl::Critic plugin for stricter subroutine checking',
    license         => 'perl',
    create_readme   => 1,
    create_packlist => 1,
    sign            => 0,

    requires        => {
        'Perl::Critic::Policy'      => 1.082,
        'Perl::Critic::Utils'       => 1.082,
        'PPI::Document'             => 0,
        'File::PathList'            => 0,
        'List::MoreUtils'           => 0,
        'English'                   => 0,
        'Exporter'                  => 0,
        'Carp'                      => 0,
        'base'                      => 0,
        'strict'                    => 0,
        'warnings'                  => 0,
    },

    build_requires => {
        'Module::Build'             => 0.40,
    },

    test_requires  => {
        'Test::More'                => 0,
        'Perl::Critic::TestUtils'   => 1.082,
    },

    configure_requires => {
        'Module::Build'             => 0.40,
    },

    add_to_cleanup  => [ qw(MANIFEST MANIFEST.bak README META*) ],

    meta_merge  => {
        resources  => {
            homepage    => 'http://perlcritic.com',
            license     => [ 'http://dev.perl.org/licenses' ],
            repository  => 'git://github.com/Perl-Critic/Perl-Critic-StricterSubs.git',
            bugtracker  => 'https://github.com/Perl-Critic/Perl-Critic-StricterSubs/issues',
        }
    },
);

$builder->create_build_script();
