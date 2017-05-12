use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PDF::Extract',
    'VERSION_FROM'	=> 'Extract.pm', # finds $VERSION
    'PREREQ_PM'		=> { }, # e.g., Module::Name => 1.1
    ($] ge '5.005') ? (
	    'AUTHOR'     => 'Noel Sharrock <noel@lgmedia.com.au>',
	    'ABSTRACT_FROM' => 'Extract.pm', # retrieve abstract from module
     ) : (),

);
