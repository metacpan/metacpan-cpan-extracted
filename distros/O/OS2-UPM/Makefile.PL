use ExtUtils::MakeMaker;

WriteMakefile(
	NAME 	=> 'OS2::UPM',
	#INC	=> '-I/usr/local/include',
	LIBS 	=> ["-lupm"],
	XSPROTOARG => '-noprototypes',
);

