use ExtUtils::MakeMaker;
require 5.6.0;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'SMS::Ringtone::RTTTL::Parser',
    'VERSION_FROM' => 'lib/SMS/Ringtone/RTTTL/Parser.pm',
    'AUTHOR' => 'Craig Manley (cmanley@cpan.org)',
    'ABSTRACT' => 'Class for parsing and validating RTTTL strings.',
    'PREREQ_PM'	=> {},
    'dist' => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'}
);