use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'POCSAG::Encode',
    'VERSION_FROM'	=> 'Encode.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Test::More' => '0.1',
	'Device::SerialPort' => '1.04'
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (
       ABSTRACT_FROM   => 'Encode.pm', # retrieve abstract from module
       AUTHOR          => 'Heikki Hannikainen <hessu@hes.iki.fi>',
       LICENSE        => 'perl',
      ) : ()
    ),
);
