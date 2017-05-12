use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Number::Encode',
    'VERSION_FROM'	=> 'Encode.pm', # finds $VERSION
    'PREREQ_PM'		=> {Digest::MD5 => 0,}, # e.g., Module::Name => 1.1
);
