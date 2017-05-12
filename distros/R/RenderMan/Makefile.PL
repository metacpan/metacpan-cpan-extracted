use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'RenderMan',
    'VERSION_FROM' => 'RenderMan.pm', # finds $VERSION
    # Please change the 'LIBS' line to point to where your BMRT lib is:
    # 'LIBS'	=> ['-L/usr/local/lib -lribout'],                  #Unix
    'LIBS'	=> ['f:/BMRT2.5/lib/libribout.lib'], #WinNT
    # If compiling for WinNT, you will need this:
    'LDDLFLAGS' => '-dll -nologo -nodefaultlib:libc -release -machine:x86',  #WinNT
    'DEFINE'	=> '',
    # Please change the 'INC' line to point to where your BMRT ri.h is:
    # 'INC'	=> '-I/usr/local/include',    #Unix
    'INC'	=> '-If:/BMRT2.5/include',  #WinNT
);
