use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'Mysql::NameLocker',
    'VERSION_FROM' => 'lib/Mysql/NameLocker.pm',
    'AUTHOR' => 'Craig Manley (cmanley@cpan.org)',
    'ABSTRACT' => 'Safe way of locking and unlocking MySQL tables using named locks.',
    'PREREQ_PM'	=> {},
    'dist' => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'}
);