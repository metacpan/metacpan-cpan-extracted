#!perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-Deprecated/Build.PL $
#     $Date: 2013-10-25 17:01:27 -0700 (Fri, 25 Oct 2013) $
#   $Author: thaljef $
# $Revision: 4208 $

use 5.006001;

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
    module_name         => 'Perl::Critic::Deprecated',
    dist_author         => 'Elliot Shank <perl@galumph.com>',
    license             => 'perl',
    dynamic_config      => 0,
    create_readme       => 1,
    create_packlist     => 1,
    sign                => 0,

    configure_requires => {
        'Module::Build'         => 0.40,
    },

    requires            => {
        'base'                  => 0,
        'Perl::Critic::Policy'  => '1.094',
        'Perl::Critic::Utils'   => '1.094',
        'Readonly'              => 0,
        'strict'                => 0,
        'warnings'              => 0,
    },

    build_requires      => {
        'Carp'                      => 0,
        'English'                   => 0,
        'Perl::Critic::TestUtils'   => '1.094',
        'Test::More'                => 0,
    },

    recommends          => {
    },

    create_makefile_pl  => 'traditional',

    meta_merge          => {
        resources   => {
            homepage    => 'http://perlcritic.com',
            license     => 'http://dev.perl.org/licenses/',
            repository  => 'http://guest@perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-Deprecated/',
            MailingList => 'http://perlcritic.tigris.org/servlets/SummarizeList?listName=users',
        }
    },

    add_to_cleanup      => [
        qw<
            MANIFEST.bak
            Makefile
            Makefile.old
            pod2htm?.tmp
            pm_to_blib
            Perl-Critic-Deprecated-*
        >,
    ],
);


$builder->create_build_script();

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
