use ExtUtils::MakeMaker;
use 5.006000;

WriteMakefile(
    'NAME'		=> 'Net::Calais',
    'ABSTRACT'	=> 'Interface to OpenCalais web service',
    'AUTHOR'	=> 'Alessandro Ranellucci <aar@cpan.org>',
    'VERSION_FROM'	=> 'lib/Net/Calais.pm',
    'PMLIBDIRS'	=> [ 'lib' ],
    'PREREQ_PM'		=> {
    	'LWP' => '5.09',
    	'XML::Writer' => '0'
    },
    'dist'         	=> { COMPRESS => 'gzip', SUFFIX => 'gz' }
);
