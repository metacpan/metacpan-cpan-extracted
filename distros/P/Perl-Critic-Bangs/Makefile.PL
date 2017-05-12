#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;


my %parms = (
    NAME                => 'Perl::Critic::Bangs',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'lib/Perl/Critic/Bangs.pm',
    ABSTRACT            => 'Perl::Critic::Bangs - A collection of policies for Perl::Critic',
    PL_FILES            => {},
    PREREQ_PM => {
        'Perl::Critic'                  => 1.098,
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
        'Test::More'                    => '0.96', # For subtest()
        'Test::Perl::Critic'            => 1.01,
    },
    LICENSE             => 'perl',

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perl-Critic-Bangs-*' },
);

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $parms{META_MERGE} = {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            repository  => 'git://github.com/petdance/perl-critic-bangs.git',
        }
    };
}

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
.PHONY: tags critic

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib --exclude=t/lib \
		--exclude=.svn --exclude='*~' \
		--languages=Perl --langmap=Perl:+.t \
		lib/ t/

critic:
	perlcritic -profile perlcriticrc -1 -quiet lib/ t/ Makefile.PL

MAKE_FRAG
}
