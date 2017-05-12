use ExtUtils::MakeMaker;

WriteMakefile(NAME	   => 'News::Newsrc',
	      VERSION_FROM => 'Newsrc.pm',      # finds $VERSION
	      DISTNAME     => 'News-Newsrc',
	      ($] >= 5.005 ?
	       (ABSTRACT   => 'Manages newsrc files',
		AUTHOR     => 'Steven McDougall (swmcd@world.std.com)') : ()),
	      dist         => {COMPRESS => 'gzip', SUFFIX => 'gz'},
	      PREREQ_PM    => { Set::IntSpan => 1.07 },
	      );

