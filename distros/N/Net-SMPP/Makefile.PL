use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'Net::SMPP',
    AUTHOR              => 'Sampo Kellomaki <sampo@symlabs.com>',
    ABSTRACT            => 'Pure perl implementation of SMPP 3.4 over TCP',
    VERSION_FROM	=> 'SMPP.pm', # finds $VERSION
    PREREQ_PM		=> {}, # e.g., Module::Name => 1.1
#    'LIBS'		=> [''], # e.g., '-lm'
#    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
#    'INC'		=> '', # e.g., '-I/usr/include/other'
);
