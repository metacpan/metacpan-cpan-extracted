use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SDL::sdlpl',
    'VERSION_FROM' => 'sdlpl.pm', # finds $VERSION
    'LIBS'	=> ['-lSDL -lSDL_image -lpng -ljpeg -lSDL_mixer -lGL'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-I/usr/local/include -I/usr/local/include/SDL',
    'OBJECT'	=> 'font.o sdlpl.o',
    
);
