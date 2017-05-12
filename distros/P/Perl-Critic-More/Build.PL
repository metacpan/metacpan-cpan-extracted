#!perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-More/Build.PL $
#     $Date: 2013-10-25 14:52:31 -0700 (Fri, 25 Oct 2013) $
#   $Author: thaljef $
# $Revision: 4190 $

use 5.006001;

use strict;
use warnings;

use lib 'inc';


use Perl::Critic::Module::Build;


my $builder = Perl::Critic::Module::Build->new(
    module_name         => 'Perl::Critic::More',
    dist_author         => 'Chris Dolan <cdolan@cpan.org>',
    license             => 'perl',
    dynamic_config      => 1,
    create_readme       => 1,
    create_packlist     => 1,
    sign                => 0,
    create_makefile_pl  => 'traditional',

    configure_requires  => {
        'Module::Build' => 0.40,
    },

    requires            => {
        'Perl::Critic'  => 1.098,
        'Readonly'      => 1.03,
    },

    build_requires      => {
        'Test::More'    => 0,
    },

    recommends          => {
        'Perl::MinimumVersion' => '0.14',
    },

    meta_merge          => {
        resources   => {
            homepage    => 'http://perlcritic.com',
            license     => 'http://dev.perl.org/licenses/',
            repository  => 'http://guest@perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-More/',
            MailingList => 'http://perlcritic.tigris.org/servlets/SummarizeList?listName=users',
        },
        no_index    => {
            file        => [
                qw<
                    TODO.pod
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
            Makefile
            Makefile.old
            MANIFEST.bak
            Perl-Critic-More-*
            pm_to_blib
            pod2htm?.tmp
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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
