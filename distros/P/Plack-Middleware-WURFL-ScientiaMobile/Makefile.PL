use ExtUtils::MakeMaker;
use 5.006000;

WriteMakefile(
    'NAME'		=> 'Plack::Middleware::WURFL::ScientiaMobile',
    'ABSTRACT'	=> 'Plack module for the ScientiaMobile WURFL Cloud Service',
    'AUTHOR'	=> 'Alessandro Ranellucci <aar@cpan.org>',
    'LICENSE'   => 'ScientiaMobile WURFL Cloud Client',
    'VERSION_FROM'	=> 'lib/Plack/Middleware/WURFL/ScientiaMobile.pm',
    'PMLIBDIRS'	=> [ 'lib' ],
    'PREREQ_PM'		=> {
    	'Plack' => '0.9957',
    	'Moo' => '0.009004',
    	'Net::WURFL::ScientiaMobile' => 0,
    	'Try::Tiny' => 0,
    	'URI::Escape' => 0,
    },
    'BUILD_REQUIRES' => {
        'HTTP::Request::Common' => 0,
        'Test::More' => 0,
        'Test::Fatal' => 0,
        'Plack::Middleware::Debug' => 0,
    },
    'dist'         	=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
    'test' => {
        'TESTS' => 't/*.t'
    },
);
