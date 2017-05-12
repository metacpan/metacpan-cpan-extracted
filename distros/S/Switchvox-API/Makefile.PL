use 5.008006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Switchvox::API',
    VERSION_FROM      => 'lib/Switchvox/API.pm', # finds $VERSION
    PREREQ_PM         => 
	{
		'LWP::UserAgent'	=> 0,
		'Crypt::SSLeay' 	=> 0,
		'HTTP::Request'		=> 0,
		'HTTP::Response'	=> 0,
		'XML::Simple'		=> 0,
		'XML::Parser'		=> 0,
	}, # e.g., Module::Name => 1.1
);
