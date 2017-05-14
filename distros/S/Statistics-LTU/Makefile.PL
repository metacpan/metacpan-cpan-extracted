use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Statistics::LTU',
	'DISTNAME'	=> 'Statistics-LTU',
	'VERSION'	=> '2.8',
	'clean'		=> {FILES=>'*.saved'}    # Delete any saved LTUs
);
