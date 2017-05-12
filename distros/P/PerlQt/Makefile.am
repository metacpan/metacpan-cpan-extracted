
SUBDIRS = $(TOPSUBDIRS)

EXTRA_DIST = admin AUTHORS COPYING ChangeLog INSTALL README TODO Makefile.cvs test.pl Makefile.PL inst-apps smoke/smoke.h smoke/Makefile.in smoke/Makefile.am smoke/qt/qtguess.pl.in smoke/qt/generate.pl.in smoke/qt/qt_smoke.h smoke/qt/generate_makefile_am.pl smoke/qt/Makefile.am smoke/qt/Makefile.in smoke/qt/header_list kalyptus/Ast.pm kalyptus/kalyptus kalyptus/kalyptusDataDict.pm  kalyptus/kdocParseDoc.pm kalyptus/Version kalyptus/ChangeLog kalyptus/kdocUtil.pm kalyptus/kdocAstUtil.pm kalyptus/README kalyptus/Iter.pm kalyptus/kalyptusCxxToSmoke.pm kalyptus/kdocLib.pm kalyptus/TODO doc/en/index.html doc/en/Makefile doc/en/PerlQt.pod doc/fr/index.html doc/fr/Makefile doc/fr/PerlQt.pod doc/css/pod.css doc/images/ex1.png doc/images/ex2.png doc/images/pqtsh.png

# not a GNU package. You can remove this line, if 
# have all needed files, that a GNU package needs
AUTOMAKE_OPTIONS = foreign 

# $(top_srcdir)/configure.in: configure.in.in $(top_srcdir)/subdirs
#	cd $(top_srcdir) && $(MAKE) -f admin/Makefile.common configure.in ;

$(top_srcdir)/subdirs:
	cd $(top_srcdir) && $(MAKE) -f admin/Makefile.common subdirs

$(top_srcdir)/acinclude.m4: $(top_srcdir)/admin/acinclude.m4.in $(top_srcdir)/admin/libtool.m4.in
	@cd $(top_srcdir) && cat admin/acinclude.m4.in admin/libtool.m4.in > acinclude.m4

MAINTAINERCLEANFILES = subdirs configure.in acinclude.m4 configure.files 

package-messages:
	$(MAKE) -f admin/Makefile.common package-messages
	$(MAKE) -C po merge

dist-hook:
	cd $(top_distdir) && perl admin/am_edit -padmin
	cd $(top_distdir) && $(MAKE) -f admin/Makefile.common subdirs

test:
	cd $(top_distdir) && LD_LIBRARY_PATH="../../smoke/qt/.libs:@qt_libraries@" PERL_DL_NONLAZY=1 perl test.pl

ChangeLog:
	perl cvs2cl.pl  -P -S --no-wrap -f ChangeLog.CVS
