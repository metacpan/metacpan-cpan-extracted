use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'String::Thai::Segmentation',
    'VERSION_FROM'	=> 'Segmentation.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Segmentation.pm', # retrieve abstract from module
       AUTHOR     => 'root <root@(none)>') : ()),
    'LIBS'		=> ['-lwordcut'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> `pkg-config --cflags glib-2.0`,
    #'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
