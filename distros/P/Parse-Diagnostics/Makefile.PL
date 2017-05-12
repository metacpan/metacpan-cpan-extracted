use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Parse/Diagnostics.pm';
my $pod = 'lib/Parse/Diagnostics.pod';
my $github = 'github.com/benkasminbullock/parse-diagnostics';
my $repo = "https://$github";

WriteMakefile (
    NAME => 'Parse::Diagnostics',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Path::Tiny' => 0,
	'C::Tokenize' => 0,
    },
    META_MERGE => {
	'meta-spec' => {
	    version => 2,
	},
        resources => {
            repository => {
		type => 'git',
		url => "git://$github.git",
		web => $repo,
	    },
            bugtracker => {
		web => "$repo/issues",
	    },
#	    homepage => 'http://',
        },
    },
    MIN_PERL_VERSION => '5.006001',
    EXE_FILES => [
	"script/parse-diagnostics",
    ],
);
