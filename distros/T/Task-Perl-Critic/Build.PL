#!perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Task-Perl-Critic-1.008/Build.PL $
#     $Date: 2012-01-04 10:40:20 -0800 (Wed, 04 Jan 2012) $
#   $Author: thaljef $
# $Revision: 4111 $

use 5.006001;

use strict;
use warnings;

use English qw< -no_match_vars >;

use Module::Build;


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
    module_name         => 'Task::Perl::Critic',
    dist_author         => 'Elliot Shank <perl@galumph.com>',
    license             => 'perl',
    dynamic_config      => 0,
    create_packlist     => 1,
    create_readme       => 1,
    sign                => 0,

    requires            => {
        'Perl::Critic'                          => '1.117',
        'Test::Perl::Critic'                    => '1.02',
        'Test::Perl::Critic::Progressive'       => '0.03',
        'criticism'                             => '1.02',
        'Perl::Critic::Bangs'                   => '1.00',
        'Perl::Critic::Compatibility'           => '1.000',
        'Perl::Critic::Dynamic'                 => '0.05',
        'Perl::Critic::Itch'                    => 0,
        'Perl::Critic::Lax'                     => '0.007',
        'Perl::Critic::Moose'                   => 0,
        'Perl::Critic::More'                    => '1.000',
        'Perl::Critic::Nits'                    => '1.000000',
        'Perl::Critic::PetPeeves::JTRAMMELL'    => '0.01',
        'Perl::Critic::Pulp'                    => 3,
        'Perl::Critic::Storable'                => 0,
        'Perl::Critic::StricterSubs'            => 0.03,
        'Perl::Critic::Swift'                   => '1.000003',
        'Perl::Critic::Tics'                    => '0.005',
    },

    build_requires      => {
        'Test::More'    => 0,
    },

    recommends          => {
    },

    create_makefile_pl  => 'traditional',

    meta_merge          => {
        resources   => {
            homepage    => 'http://perlcritic.com',
            license     => 'http://dev.perl.org/licenses/',
            repository  => 'http://guest@perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Task-Perl-Critic/',
            MailingList => 'http://perlcritic.tigris.org/servlets/SummarizeList?listName=users',
        }
    },

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
            README
            Task-Perl-Critic-*
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
