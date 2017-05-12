use 5.006000;
use ExtUtils::MakeMaker;

# Add the `devtest` target to run regression and POD tests in one go
sub MY::postamble {
    return <<'END';
devtest :
	REGRESSION_TESTS=1 POD_TESTS=1 $(MAKE) test

END
}

# Override `disttest` so it would behave as `devtest`
sub MY::dist_test {
    return <<'END';
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) devtest $(PASTHRU)

END
}

my $MM_VERSION  = $ExtUtils::MakeMaker::VERSION;
my $github_repo = 'https://github.com/nohuhu/RPC-ExtDirect-Server';

my %MAIN_REQ = (
    'RPC::ExtDirect'       => '3.24',
    'CGI::ExtDirect'       => '3.24',
    'HTTP::Server::Simple' => '0.44',
);

my %TEST_REQ = (
    'HTTP::Tiny' => '0.014',
    'Test::More' => '0.82',  # for explain()
);

WriteMakefile(
    NAME         => 'RPC::ExtDirect::Server',
    VERSION_FROM => 'lib/RPC/ExtDirect/Server.pm',
    ABSTRACT     => 'A tiny but capable pure Perl Ext.Direct server',
    AUTHOR       => 'Alex Tokarev <tokarev@cpan.org>',
    LICENSE      => 'perl',

    ($MM_VERSION >= 6.64
        ? (
            TEST_REQUIRES => \%TEST_REQ,
            PREREQ_PM     => \%MAIN_REQ,
        )
        : (
            ($MM_VERSION >= 6.5503
                ? (
                    BUILD_REQUIRES => \%TEST_REQ,
                    PREREQ_PM      => \%MAIN_REQ,
                )
                : (
                    PREREQ_PM => {
                        %TEST_REQ,
                        %MAIN_REQ,
                    },
                ),
            ),
        ),
    ),


    ($MM_VERSION >= 6.48 ? ( MIN_PERL_VERSION => 5.006000 ) : ()),

    ($MM_VERSION >= 6.46
        ? ( META_MERGE => {
                resources => {
                    bugtracker => "$github_repo/issues/",
                    repository => $github_repo,
                },
            },
        )
        : ()
    ),
);

