use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Stats::LikeR',
	VERSION_FROM      => 'lib/Stats/LikeR.pm', 
	PREREQ_PM         => {},
	CCFLAGS           => '-std=c99',
	LIBS              => ['-lm'], 
	DEFINE            => '', 
	INC               => '-I.', 
);
