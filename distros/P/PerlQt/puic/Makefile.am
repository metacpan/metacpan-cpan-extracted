AM_CPPFLAGS = -DUIC -DQT_INTERNAL_XML
AM_CXXFLAGS= $(KDE_CXXFLAGS)

bin_PROGRAMS = puic

puic_SOURCES = widgetdatabase.cpp uic.cpp subclassing.cpp parser.cpp object.cpp main.cpp form.cpp embed.cpp domtool.cpp 
puic_LDADD   =  $(LIB_QT) $(LIBZ)

man_MANS = puic.1

EXTRA_DIST = domtool.cpp domtool.h embed.cpp form.cpp globaldefs.h main.cpp object.cpp parser.cpp parser.h subclassing.cpp uic.cpp uic.h widgetdatabase.cpp widgetdatabase.h widgetinterface.h puic.1

# These paths are KDE specific :
# kde_bindir          Where executables should go to. Use bin_PROGRAMS or bin_SCRIPTS.
# kde_libdir          Where shared libraries should go to. Use lib_LTLIBRARIES.
# kde_moduledir       Where modules (e.g. parts) should go to. Use kde_module_LTLIBRARIES.
# kde_styledir        Where Qt/KDE widget styles should go to (new in KDE 3).
# kde_designerdir     Where Qt Designer plugins should go to (new in KDE 3).

# set the include path for X, qt and KDE
INCLUDES= $(all_includes)

METASOURCES = AUTO

# the library search path. 
puic_LDFLAGS = $(all_libraries) $(KDE_RPATH)

messages: 
	LIST=`find . -name \*.h -o -name \*.hh -o -name \*.H -o -name \*.hxx -o -name \*.hpp -o -name \*.cpp -o -name \*.cc -o -name \*.cxx -o -name \*.ecpp -o -name \*.C`; \
	if test -n "$$LIST"; then \
	 $(XGETTEXT) $$LIST -o $(podir)/puic.pot; \
	fi

