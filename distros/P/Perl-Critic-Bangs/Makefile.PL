#!perl

use strict;
use warnings;
use 5.010;

use ExtUtils::MakeMaker 6.46;


my %parms = (
    NAME                => 'Perl::Critic::Bangs',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'lib/Perl/Critic/Bangs.pm',
    ABSTRACT            => 'Perl::Critic::Bangs - A collection of policies for Perl::Critic',
    PL_FILES            => {},
    MIN_PERL_VERSION    => '5.10.1',
    LICENSE             => 'artistic_2',
    PREREQ_PM => {
        'List::MoreUtils'               => 0,
        'Perl::Critic'                  => 1.122,
        'Perl::Critic::Policy'          => 0,
        'Perl::Critic::PolicyFactory'   => 0,
        'Perl::Critic::PolicyParameter' => 0,
        'Perl::Critic::TestUtils'       => 0,
        'Perl::Critic::UserProfile'     => 0,
        'Perl::Critic::Utils'           => 0,
        'Perl::Critic::Violation'       => 0,
        'PPI::Cache'                    => 0,
        'PPI::Document'                 => 0,
        'Readonly'                      => 0,
    },
    TEST_REQUIRES => {
        'Test::More'                    => '0.96', # For subtest()
        'Test::Perl::Critic'            => 1.01,
    },
    META_MERGE => {
        resources => {
            license     => 'https://opensource.org/licenses/Artistic-2.0',
            bugtracker  => 'https://github.com/petdance/perl-critic-bangs',
            repository  => 'git://github.com/petdance/perl-critic-bangs.git',
        }
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perl-Critic-Bangs-*' },
);

WriteMakefile( %parms );

package MY;
sub MY::libscan {
    my $self = shift;
    my $path = shift;

    $path = $self->SUPER::libscan($path);

    # I have a bunch of symlinks in the root.  Ignore them.
    return '' if -l $path;
    return $path;
};

sub MY::postamble {
    return <<'MAKE_FRAG';
.PHONY: tags critic nytprof

#PERLCRITIC=$(which perlcritic)
PERLCRITIC=/opt/local/libexec/perl5.12/sitebin//perlcritic

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib --exclude=t/lib \
		--exclude=.svn --exclude='*~' \
		--languages=Perl --langmap=Perl:+.t \
		lib/ t/

nytprof: all
	$(PERL) -d:NYTProf $(PERLCRITIC) -profile perlcriticrc -1 -quiet lib/ t/ Makefile.PL >> /dev/null 2>&1
	nytprofhtml

critic:
	$(PERLCRITIC) -profile perlcriticrc -1 -quiet lib/ t/ Makefile.PL

MAKE_FRAG
}
