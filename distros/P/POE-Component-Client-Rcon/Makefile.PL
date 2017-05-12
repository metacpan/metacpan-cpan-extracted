#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'POE::Component::Client::Rcon',
    ( ($^O eq 'MacOS')
      ? ()
      : ( AUTHOR	=> 'Andrew Chen <achen-poe-rcon@divo.net>',
          ABSTRACT	=> 'POE-based implementation of the Rcon protocol.',
	)
    ),
    VERSION_FROM	=> 'Rcon.pm',
    dist		=> { 'COMPRESS'	=> 'gzip -9f',
			     'SUFFIX'	=> 'gz',
			   },
    PREREQ_PM		=> { Carp		=> 0,
    			     Socket		=> 0,
			     POE		=> 0.15,
			     Time::HiRes	=> 0,
			   },
);

exit 0 unless $^O eq 'MacOS';
