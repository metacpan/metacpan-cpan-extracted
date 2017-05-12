use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Piet::Interpreter',
    'VERSION_FROM'	=> 'Interpreter.pm', # finds $VERSION
    'PREREQ_PM'		=> {Image::Magick => 5.39,
                            POSIX         => 1.03}, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Interpreter.pm', # retrieve abstract from module
       AUTHOR     => 'Marc Majcher <piet-interpreter@majcher.com>') : ()),
);
