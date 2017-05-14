# $Id: Makefile.PL 511 2008-09-09 13:38:36Z khera $
use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'RWDE::Doxy',
	      PREREQ_PM => {
		  'RWDE' => 0,
	      },
	      dist => {
		  PREOP => 'pod2text Doxy.pm > README',
	      },
	      EXE_FILES => [ 'bin/doxy' ],
#	      VERSION => sprintf "%d", q$Revision: 511 $ =~ /(\d+)/,
	      VERSION_FROM => 'Doxy.pm',
	      );
