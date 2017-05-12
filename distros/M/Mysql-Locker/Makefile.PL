use ExtUtils::MakeMaker;
require 5.6.0;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'Mysql::Locker',
    'VERSION_FROM' => 'lib/Mysql/Locker.pm',
    'AUTHOR' => 'Craig Manley (c.manley@skybound.nl)',
    'ABSTRACT' => 'Safe way of locking and unlocking MySQL tables.',
    'PREREQ_PM'	=> {},
    'dist' => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'}
);