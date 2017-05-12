use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mobile::UserAgent',
    'VERSION_FROM' => 'lib/Mobile/UserAgent.pm',
    'AUTHOR' => 'Craig Manley',
    'ABSTRACT' => 'Mobile user agent string parsing class.',
    'PREREQ_PM'	=> {'Class::Singleton' => 0},
    'dist' => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'}
);
