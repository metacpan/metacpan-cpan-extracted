use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'    => 'Sergey Gribov (sergey@sergey.com)',
    'NAME'	=> 'Tasks',
    'VERSION_FROM' => 'Tasks.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other'
    'PREREQ_PM' => {
        'XML::Parser'   => '0', # or a minimum workable version
    }
);
