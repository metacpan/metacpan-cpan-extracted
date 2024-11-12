use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Parse/Gitignore.pm';
my $pod = 'lib/Parse/Gitignore.pod';
my $github = 'github.com/benkasminbullock/parse-gitignore';
my $repo = "https://$github";

WriteMakefile (
    NAME => 'Parse::Gitignore',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <benkasminbullock@gmail.com>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'File::Slurper' => '0.010',
	'File::Spec' => '3.40',
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
);
