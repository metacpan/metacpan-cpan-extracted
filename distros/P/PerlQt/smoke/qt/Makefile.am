lib_LTLIBRARIES = libsmokeqt.la

# set the include path for X, qt and KDE
INCLUDES         = -I$(srcdir)/.. $(all_includes)

EXTRA_DIST=generate.pl.in qtguess.pl.in qt_smoke.h Makefile.am Makefile.in

# the library search path. 
libsmokeqt_la_LDFLAGS = -version-info 3:1:2 -no-undefined $(all_libraries) $(GL_CFLAGS) $(KDE_RPATH)

# the libraries to link against.
libsmokeqt_la_LIBADD   = $(LIB_QT) $(GL_LIBS)

# which sources should be compiled for perlqtkde
libsmokeqt_la_SOURCES =  smokedata.cpp x_1.cpp x_2.cpp x_3.cpp x_4.cpp x_5.cpp x_6.cpp x_7.cpp \
 x_8.cpp x_9.cpp x_10.cpp x_11.cpp x_12.cpp x_13.cpp x_14.cpp x_15.cpp \
 x_16.cpp x_17.cpp x_18.cpp x_19.cpp x_20.cpp
