use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'PowerBuilder::ORCA',
    'VERSION_FROM' => 'ORCA.pm', # finds $VERSION
#    'LIBS'	=> ['PBORCA.LIB'],   # e.g., '-lm' 
    'LIBS'	=> [],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'PowerBuilder ORCA', # retrieve abstract from module
       AUTHOR     => 'Ilya Chelpanov (chelpanov@mail.ru)') : ()),
);
