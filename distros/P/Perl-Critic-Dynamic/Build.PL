#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-Dynamic-0.05/Build.PL $
#     $Date: 2010-09-30 15:03:52 -0700 (Thu, 30 Sep 2010) $
#   $Author: thaljef $
# $Revision: 3948 $
########################################################################

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
    }

    sub ACTION_distdir {
        my ($self) = @_;

        $self->depends_on('authortest');

        return $self->SUPER::ACTION_distdir();
    }

    sub ACTION_manifest {
        my ($self, @arguments) = @_;

        # Make sure we get rid of files that no longer exist.
        if (-e 'MANIFEST') {
            unlink 'MANIFEST' or die "Can't unlink MANIFEST: $OS_ERROR";
        }

        return $self->SUPER::ACTION_manifest(@arguments);
    }

END_SUBCLASS

my $builder = $class->new(
    module_name     => 'Perl::Critic::Dynamic',
    dist_author     => 'Jeffrey Thalhammer <thaljef@cpan.org>',
    dist_abstract   => 'Dynamic policies for Perl::Critic.',
    license         => 'perl',
    dynamic_config  => 1,
    create_readme   => 1,
    create_packlist => 1,
    sign            => 0,

    requires        => {
        'Perl::Critic::Utils'   => 1.108,
        'Perl::Critic::Policy'  => 1.108,
        'Devel::Symdump'        => 2.07,
        'Readonly'              => 0,
        'Storable'              => 2.16,
    },
    build_requires  => {
        'Test::More'            => 0,
    },
    meta_merge      => {
        resources   => {
            homepage    => 'http://perlcritic.com',
            license     => 'http://dev.perl.org/licenses/',
            repository  => 'http://guest@perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-Dynamic/',
            MailingList => 'http://perlcritic.tigris.org/servlets/SummarizeList?listName=users',
        }
    },
    add_to_cleanup  => [
        qw<
            Debian_CPANTS.txt
            Makefile
            Makefile.old
            MANIFEST.bak
            META.yml
            pm_to_blib
            README
          >,
   ]
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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
