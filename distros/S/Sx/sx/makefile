#
# Makefile for the libsx library and sample demo program.
#

#
#  If you have trouble building, edit the file ../libsx_defs and
# change stuff there.  That file gets included everywhere else, so
# you only need to change things there once.
#
include libsx_defs

#
# You shouldn't need to modify anything below here.
#
#

LIBSXOBJS  = draw.o toggle.o button.o string_entry.o libsx.o misc.o list.o\
             font.o scrollbar.o menu.o popups.o colormap.o DrawingA.o\
	     Dialog.o version.o ThreeCom.o ThreeList.o Canvas.o


all : libsx.a

libsx.a : $(LIBSXOBJS) 
	rm -f libsx.a
	ar rc libsx.a $(LIBSXOBJS)
	ranlib libsx.a


draw.o : draw.c ../libsx.h ../libsx_private.h

toggle.o : toggle.c ../libsx.h ../libsx_private.h

button.o : button.c ../libsx.h ../libsx_private.h

string_entry.o : string_entry.c ../libsx.h ../libsx_private.h

libsx.o : libsx.c ../libsx.h ../libsx_private.h

misc.o : misc.c ../libsx.h ../libsx_private.h

list.o : list.c ../libsx.h ../libsx_private.h

scrollbar.o : scrollbar.c ../libsx.h ../libsx_private.h

menu.o : menu.c ../libsx.h ../libsx_private.h check_mark.h

popups.o : popups.c ../libsx.h ../libsx_private.h Dialog.h

colormap.o : colormap.c ../libsx.h ../libsx_private.h

font.o : font.c ../libsx.h ../libsx_private.h

Dialog.o : Dialog.c Dialog.h


clean:
	rm -f *.o *~ core libsx.a
