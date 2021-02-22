use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Table/Trans.pm';
my $pod = 'lib/Table/Trans.pod';
my $github = 'github.com/benkasminbullock/table-trans';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'Table::Trans',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'JSON::Parse' => '0.60',
	'JSON::Create' => '0.30',
	'Table::Readable' => '0.05',
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
