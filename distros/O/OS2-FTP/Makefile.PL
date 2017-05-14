use ExtUtils::MakeMaker;

WriteMakefile(
	NAME 	=> 'OS2::FTP',
	LIBS 	=> ["-lftpapi"],
	#INC	=> '-I/usr/local/include',
	XSPROTOARG => '-noprototypes',
);

