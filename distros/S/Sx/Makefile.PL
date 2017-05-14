use ExtUtils::MakeMaker;

WriteMakefile(
# If your X11 libraries are not in a 'standard place', add a
# -L/where/are/the/X11/libs just before -lXaw.
	       'LIBS' => '-L/local/X11R6/lib -lXaw3d -lXmu -lXext -lXt -lX11',
#	       'LIBS' => '-lXaw -lXmu -lXext -lXt -lX11',
	       'NAME' => 'Sx',
	       'DISTNAME' => 'Sx',
	       'VERSION' => '2.3',
# uncomment and update the following line if X11 include files are not
# in /usr/include/X11
	       'INC' => '-DXAW3D -I/local/X11R6/include',
	       'OBJECT' => 'Sx.o suplibsx.o' ,
	       'MYEXTLIB' => 'sx/libsx.a',
# If you have trouble with Dynamic linking of X11 library, try the following
#	       'LDFROM' => 'Sx.o suplibsx.o sx/libsx.a -Bstatic'
);



sub MY::postamble {
    '
$(MYEXTLIB): sx/makefile
	cd sx; $(MAKE) all

clean ::
	cd sx; $(MAKE) clean
';
}
