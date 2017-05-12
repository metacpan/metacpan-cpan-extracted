# Makefile.PL for Slauth
use 5.008005;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Slauth::Register::Mailman',
    'DISTNAME'     	=> 'Slauth-Register-Mailman',
    'VERSION_FROM'      => 'lib/Slauth/Register/Mailman.pm', # finds $VERSION
    'PREREQ_PM'         => {
				Slauth => 0.01,
				CGI => 3.00,
				CGI::Carp => 1.28,
				IO::Pipe => 1.123,
    			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      ('ABSTRACT_FROM'  => 'lib/Slauth/Register/Mailman.pm', # retrieve abstract from module
       'AUTHOR'         => 'Ian Kluft <ikluft@thunder.sbay.org>') : ()),
    'LIBS'              => [''], # e.g., '-lm'
    'DEFINE'            => '', # e.g., '-DHAVE_SOMETHING'
    'INC'               => '-I.', # e.g., '-I. -I/usr/include/other'
);
