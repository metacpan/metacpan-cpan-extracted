use 5.034000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RPi::MultiPCA9685',
    VERSION_FROM      => 'lib/RPi/MultiPCA9685.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'RPi::I2C'=>'2','POSIX'=>'0','Exporter'=>'0'}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/RPi/MultiPCA9685.pm', # retrieve abstract from module
    EXE_FILES         => ['examples/PCA9685-minimal.pl'],
    AUTHOR            => 'rolf <rolf@bechele.de>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
);
