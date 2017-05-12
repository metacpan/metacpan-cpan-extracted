use ExtUtils::MakeMaker;
use 5.006000;

WriteMakefile(
    'NAME'		=> 'POE::Component::Gearman::Client',
    'ABSTRACT'	=> 'Asynchronous client module for Gearman for POE applications',
    'AUTHOR'	=> 'Alessandro Ranellucci <aar@cpan.org>',
    'VERSION_FROM'	=> 'lib/POE/Component/Gearman/Client.pm',
    'PMLIBDIRS'	=> [ 'lib' ],
    'PREREQ_PM'		=> {
    	'POE' => '0',
    	'Gearman::Task' => 0,
    	'List::Util' => 0,
    	'POE::Component::Client::TCP' => 0,
    	'Scalar::Util' => 0
    },
    'dist'         	=> { COMPRESS => 'gzip', SUFFIX => 'gz' }
);
