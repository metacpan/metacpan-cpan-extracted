#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'POE::Component::Client::Halo',
    ( ($^O eq 'MacOS')
      ? ()
      : ( AUTHOR	=> 'Andrew Chen <achen-poe-halo@divo.net>',
          ABSTRACT	=> 'POE-based implementation of the Halo query protocol.',
	)
    ),
    VERSION_FROM	=> 'Halo.pm',
    dist		=> { 'COMPRESS'	=> 'gzip -9f',
			     'SUFFIX'	=> 'gz',
			   },
    PREREQ_PM		=> { Carp		=> 0,
    			     Socket		=> 0,
			     POE		=> 0.15,
			   },
);

exit 0 unless $^O eq 'MacOS';
