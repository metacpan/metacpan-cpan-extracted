use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.1 2002/01/07 15:00:47 jgsmith Exp $

WriteMakefile( NAME => 'Perl::WhichPhase',
               VERSION_FROM => 'lib/Perl/WhichPhase.pm',
               dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
             );
