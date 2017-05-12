use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Sys::Protect',
    'VERSION_FROM'	=> 'lib/Sys/Protect.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'ABSTRACT_FROM' => 'lib/Sys/Protect.pm', # retrieve abstract from module
    'AUTHOR'     => 'Artur Bergman <sky@crucially.net>, Brad Fitzpatrick <brad@danga.com>',
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I.', # e.g., '-I. -I/usr/include/other'
);
