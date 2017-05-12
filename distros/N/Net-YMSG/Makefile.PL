use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'  => 'Varun kacholia ( varunk@cse.iitb.ac.in)',
    'NAME'		=> 'Net::YMSG',
    'VERSION_FROM'	=> 'YMSG.pm',
    'PREREQ_PM'		=> {
		'Digest::MD5' => 0.0,
		'Crypt::PasswdMD5' => 0.0,
	},
);
