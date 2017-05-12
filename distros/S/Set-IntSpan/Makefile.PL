use ExtUtils::MakeMaker;

WriteMakefile(NAME         => 'Set::IntSpan',
	      VERSION_FROM => 'IntSpan.pm',   # finds $VERSION
	      DISTNAME     => 'Set-IntSpan',
	      ($] >= 5.005 ?
	       (ABSTRACT   => 'Manages sets of integers, newsrc style',
		AUTHOR     => 'Steven McDougall (swmcd@world.std.com)') : ()),
	      dist         => {COMPRESS => 'gzip', SUFFIX => 'gz'}
	      );
