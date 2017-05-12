use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Net::Zemanta',

	VERSION_FROM	=> 'lib/Net/Zemanta/Method.pm', 
	PREREQ_PM	=> {
				'Encode'	=> 0,
				'JSON'		=> '2.00',
				'LWP'		=> '5.09',
				'Test::More'	=> 0,
				'Pod::Checker'	=> '1.19'
			},   

	LICENSE		=> 'perl',

	($] >= 5.005 ?
		(ABSTRACT 	=> 'Perl bindings for services provided by Zemanta', 
		 AUTHOR		=> 'Tomaz Solc <tomaz@zemanta.com>') : ()),
);
