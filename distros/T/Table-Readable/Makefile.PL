use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Table/Readable.pm';
my $pod = 'lib/Table/Readable.pod';
my $repo = 'https://github.com/benkasminbullock/Table-Readable';

WriteMakefile (
    NAME => 'Table::Readable',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    PREREQ_PM => {
	'Carp' => 0,
    },
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
	no_index => {
	    file => ['t/TRTest.pm',],
	},
    },
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.006001',
);
