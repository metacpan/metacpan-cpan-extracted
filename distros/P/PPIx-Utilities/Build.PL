#!perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/PPIx-Utilities/Build.PL $
#     $Date: 2009-06-26 10:48:29 -0400 (Fri, 26 Jun 2009) $
#   $Author: clonezone $
# $Revision: 3365 $

use 5.006001;

use strict;
use warnings;

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

my $ppi_version = '1.208';

my $builder = $class->new(
    module_name         => 'PPIx::Utilities',
    dist_author         => 'Elliot Shank <perl@galumph.com>',
    license             => 'perl',
    dynamic_config      => 0,
    create_license      => 1,
    create_makefile_pl  => 'traditional',
    create_packlist     => 1,
    create_readme       => 1,
    sign                => 0,

    requires            => {
        'base'                      => 0,
        'Exception::Class'          => 0,
        'Exporter'                  => 0,
        'PPI'                       => $ppi_version,
        'PPI::Document::Fragment'   => $ppi_version,
        'Readonly'                  => 0,
        'Scalar::Util'              => 0,
        'strict'                    => 0,
        'Task::Weaken'              => 0, # Ensure a proper Scalar::Util.
        'warnings'                  => 0,
    },

    build_requires      => {
        'Data::Dumper'  => 0,
        'PPI::Document' => $ppi_version,
        'PPI::Dumper'   => $ppi_version,
        'Test::Deep'    => 0,
        'Test::More'    => 0,
    },

    recommends          => {
        'Readonly::XS'  => 0,
    },

    meta_merge          => {
        resources   => {
            license     => 'http://dev.perl.org/licenses/',
            repository  => 'http://guest@perlcritic.tigris.org/svn/perlcritic/trunk/distributions/PPIx-Utilities/',
            MailingList => 'http://perlcritic.tigris.org/servlets/SummarizeList?listName=users',
        },
        no_index        => {
            file        => [ ],
            directory   => [ qw< t xt > ],
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
            README
            PPIx-Utilities-*
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
