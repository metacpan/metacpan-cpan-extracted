use ExtUtils::MakeMaker;

%mods = (
	'DBI'		=> '0',
	'DBD::CSV'	=> '0'
	);

WriteMakefile(
	'NAME' 		=> 	"Register",
	'VERSION_FROM' 	=> 	"Register.pm",
	'PREREQ_PM'	=>	\%mods,
	'dist'		=>	{
				COMPRESS	=>	'gzip -9f',
				SUFFIX		=>	'gz',
				DIST_DEFAULT	=>	'all tardist',
				DIST_CP		=>	'ln'
				}
);
