use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PDF::Xtract',
    'VERSION_FROM'	=> 'Xtract.pm', # finds $VERSION
    'PREREQ_PM'		=> { }, # e.g., Module::Name => 1.1
    ($] ge '5.005') ? (
	    'AUTHOR'     => 'Sunil S <sunils_AT_hpcl_DOT_co_DOT_in>',
	    'ABSTRACT_FROM' => 'Xtract.pm', # retrieve abstract from module
     ) : (),

);

