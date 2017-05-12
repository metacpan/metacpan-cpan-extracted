use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# $Id: Makefile.PL,v 1.1 2001/10/11 12:21:15 brendan Exp $


my @programs_to_install = qw( );

WriteMakefile(
    'NAME'	=> 'Syndication::NewsML',
    'VERSION_FROM' => 'NewsML.pm', # finds $VERSION
    'dist'          => { COMPRESS => 'gzip -9f --best',
                         SUFFIX => '.gz',
                         PREOP => 'bin/dist' },
    'EXE_FILES'     => [ map {"bin/$_"} @programs_to_install ],
    'PREREQ_PM' => { 
        'XML::DOM' => 0, # requires XML::DOM (any version)
    },
	($] ge '5.005') ? (
		'AUTHOR' => 'Brendan Quinn (brendan@clueful.com.au)',
		'ABSTRACT' => 'A parser for the NewsML news distribution markup language.',
    ) : (),
);
