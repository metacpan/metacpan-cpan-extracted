# This Makefile is for the Win32::Wingraph extension to perl.
#
# It was generated automatically by MakeMaker version
# 5.45 (Revision: 1.222) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#
#   MakeMaker Parameters:

#	LDFROM => q[$(OBJECT)]
#	LIBS => [q[gdi32.lib user32.lib fm.lib]]
#	NAME => q[Win32::Wingraph]
#	VERSION_FROM => q[Wingraph.pm]

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via d:\perl\5.6.0\lib\MSWin32-x86-multi-thread/Config.pm)

# They may have been overridden via Makefile.PL or on the command line
AR = lib
CC = cl
CCCDLFLAGS =  
CCDLFLAGS =  
DLEXT = dll
DLSRC = dl_win32.xs
LD = link
LDDLFLAGS = -dll -nologo -nodefaultlib -release  -libpath:"d:\perl\5.6.0\lib\MSWin32-x86-multi-thread\CORE"  -machine:x86
LDFLAGS = -nologo -nodefaultlib -release  -libpath:"d:\perl\5.6.0\lib\MSWin32-x86-multi-thread\CORE"  -machine:x86
LIBC = msvcrt.lib
LIB_EXT = .lib
OBJ_EXT = .obj
OSNAME = MSWin32
OSVERS = 4.0
RANLIB = rem
SO = dll
EXE_EXT = .exe
FULL_AR = 


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
NAME = Win32::Wingraph
DISTNAME = Win32-Wingraph
NAME_SYM = Win32_Wingraph
VERSION = 0.2
VERSION_SYM = 0_2
XS_VERSION = 0.2
INST_BIN = ..\blib\bin
INST_EXE = ..\blib\script
INST_LIB = ..\blib\lib
INST_ARCHLIB = ..\blib\arch
INST_SCRIPT = ..\blib\script
PREFIX = d:\perl
INSTALLDIRS = site
INSTALLPRIVLIB = d:\perl\5.6.0\lib
INSTALLARCHLIB = d:\perl\5.6.0\lib\MSWin32-x86-multi-thread
INSTALLSITELIB = d:\perl\site\5.6.0\lib
INSTALLSITEARCH = d:\perl\site\5.6.0\lib\MSWin32-x86-multi-thread
INSTALLBIN = $(PREFIX)\5.6.0\bin\MSWin32-x86-multi-thread
INSTALLSCRIPT = $(PREFIX)\5.6.0\bin
PERL_LIB = d:\perl\5.6.0\lib
PERL_ARCHLIB = d:\perl\5.6.0\lib\MSWin32-x86-multi-thread
SITELIBEXP = d:\perl\site\5.6.0\lib
SITEARCHEXP = d:\perl\site\5.6.0\lib\MSWin32-x86-multi-thread
LIBPERL_A = libperl.lib
FIRST_MAKEFILE = Makefile
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = D:\perl\5.6.0\lib\MSWin32-x86-multi-thread\CORE
PERL = D:\perl\5.6.0\bin\perl.exe
FULLPERL = D:\perl\5.6.0\bin\perl.exe

VERSION_MACRO = VERSION
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"

MAKEMAKER = 
MM_VERSION = 5.45

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# ROOTEXT = Directory part of FULLEXT with leading slash (eg /DBD)  !!! Deprecated from MM 5.32  !!!
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = Win32\Wingraph
BASEEXT = Wingraph
PARENT_NAME = Win32
DLBASE = $(BASEEXT)
VERSION_FROM = Wingraph.pm
OBJECT = $(BASEEXT)$(OBJ_EXT)
LDFROM = $(OBJECT)
LINKTYPE = dynamic

# Handy lists of source code files:
XS_FILES= Wingraph.xs
C_FILES = Wingraph.c
O_FILES = Wingraph.obj
H_FILES = 
HTMLLIBPODS    = 
HTMLSCRIPTPODS = 
MAN1PODS = 
MAN3PODS = NPRG.pm \
	Wingraph.pm
HTMLEXT = html
INST_MAN1DIR = ..\blib\man1
INSTALLMAN1DIR = d:\perl\5.6.0\man\man1
MAN1EXT = 1
INST_MAN3DIR = ..\blib\man3
INSTALLMAN3DIR = d:\perl\5.6.0\man\man3
MAN3EXT = 3

# work around a famous dec-osf make(1) feature(?):
makemakerdflt: all

.SUFFIXES: .xs .c .C .cpp .cxx .cc $(OBJ_EXT)

# Nick wanted to get rid of .PRECIOUS. I don't remember why. I seem to recall, that
# some make implementations will delete the Makefile when we rebuild it. Because
# we call false(1) when we rebuild it. So make(1) is not completely wrong when it
# does so. Our milage may vary.
# .PRECIOUS: Makefile    # seems to be not necessary anymore

.PHONY: all config static dynamic test linkext manifest

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)\Config.pm $(PERL_INC)\config.h

# Where to put things:
INST_LIBDIR      = $(INST_LIB)\Win32
INST_ARCHLIBDIR  = $(INST_ARCHLIB)\Win32

INST_AUTODIR     = $(INST_LIB)\auto\$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)\auto\$(FULLEXT)

INST_STATIC  = $(INST_ARCHAUTODIR)\$(BASEEXT)$(LIB_EXT)
INST_DYNAMIC = $(INST_ARCHAUTODIR)\$(DLBASE).$(DLEXT)
INST_BOOT    = $(INST_ARCHAUTODIR)\$(BASEEXT).bs

EXPORT_LIST = Wingraph.def

PERL_ARCHIVE = $(PERL_INC)\perl56.lib

TO_INST_PM = NPRG.pm \
	Wingraph.pm

PM_TO_BLIB = NPRG.pm \
	$(INST_LIBDIR)\NPRG.pm \
	Wingraph.pm \
	$(INST_LIBDIR)\Wingraph.pm


# --- MakeMaker tool_autosplit section:

# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -MAutoSplit  -e "autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1);"


# --- MakeMaker tool_xsubpp section:

XSUBPPDIR = D:\perl\5.6.0\lib\ExtUtils
XSUBPP = $(XSUBPPDIR)/xsubpp
XSPROTOARG = 
XSUBPPDEPS = $(XSUBPPDIR)\typemap typemap $(XSUBPP)
XSUBPPARGS = -typemap $(XSUBPPDIR)\typemap -typemap typemap


# --- MakeMaker tools_other section:

SHELL = cmd /x /c
CHMOD = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e chmod
CP = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e cp
LD = link
MV = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e mv
NOOP = rem
RM_F = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e rm_f
RM_RF = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e rm_rf
TEST_F = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e test_f
TOUCH = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e touch
UMASK_NULL = umask 0
DEV_NULL = > NUL

# The following is a portable way to say mkdir -p
# To see which directories are created, change the if 0 to if 1
MKPATH = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e mkpath

# This helps us to minimize the effect of the .exists files A yet
# better solution would be to have a stable file in the perl
# distribution with a timestamp of zero. But this solution doesn't
# need any changes to the core distribution and works with older perls
EQUALIZE_TIMESTAMP = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e eqtime


# --- MakeMaker dist section skipped.

# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:

CCFLAGS = -O1 -MD -DNDEBUG -DWIN32 -D_CONSOLE -DNO_STRICT -DPERL_IMPLICIT_CONTEXT -DPERL_IMPLICIT_SYS -DPERL_MSVCRT_READFIX
OPTIMIZE = -O1 -MD -DNDEBUG
PERLTYPE = 
LARGE = 
SPLIT = 
MPOLLUTE = 


# --- MakeMaker const_loadlibs section:

# Win32::Wingraph might depend on some other libraries:
# See ExtUtils::Liblist for details
#
LDLOADLIBS =   oldnames.lib kernel32.lib user32.lib gdi32.lib winspool.lib  comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib  netapi32.lib uuid.lib wsock32.lib mpr.lib winmm.lib  version.lib odbc32.lib odbccp32.lib msvcrt.lib
LD_RUN_PATH = 


# --- MakeMaker const_cccmd section:
CCCMD = $(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) \
	$(PERLTYPE) $(LARGE) $(SPLIT) $(MPOLLUTE) $(DEFINE_VERSION) \
	$(XS_DEFINE_VERSION)

# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:
PASTHRU = -nologo

# --- MakeMaker c_o section:

.c$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c

.cpp$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cpp

.cxx$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cxx

.cc$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cc


# --- MakeMaker xs_c section:

.xs.c:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.xsc && $(MV) $*.xsc $*.c


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:

#all ::	config $(INST_PM) subdirs linkext manifypods

all :: pure_all htmlifypods manifypods
	@$(NOOP)

pure_all :: config pm_to_blib subdirs linkext
	@$(NOOP)

subdirs :: $(MYEXTLIB)
	@$(NOOP)

config :: Makefile $(INST_LIBDIR)\.exists
	@$(NOOP)

config :: $(INST_ARCHAUTODIR)\.exists
	@$(NOOP)

config :: $(INST_AUTODIR)\.exists
	@$(NOOP)

$(INST_AUTODIR)\.exists :: D:\perl\5.6.0\lib\MSWin32-x86-multi-thread\CORE\perl.h
	@$(MKPATH) $(INST_AUTODIR)
	@$(EQUALIZE_TIMESTAMP) D:\perl\5.6.0\lib\MSWin32-x86-multi-thread\CORE\perl.h $(INST_AUTODIR)\.exists

	-@$(CHMOD) $(PERM_RWX) $(INST_AUTODIR)

$(INST_LIBDIR)\.exists :: D:\perl\5.6.0\lib\MSWin32-x86-multi-thread\CORE\perl.h
	@$(MKPATH) $(INST_LIBDIR)
	@$(EQUALIZE_TIMESTAMP) D:\perl\5.6.0\lib\MSWin32-x86-multi-thread\CORE\perl.h $(INST_LIBDIR)\.exists

	-@$(CHMOD) $(PERM_RWX) $(INST_LIBDIR)

$(INST_ARCHAUTODIR)\.exists :: D:\perl\5.6.0\lib\MSWin32-x86-multi-thread\CORE\perl.h
	@$(MKPATH) $(INST_ARCHAUTODIR)
	@$(EQUALIZE_TIMESTAMP) D:\perl\5.6.0\lib\MSWin32-x86-multi-thread\CORE\perl.h $(INST_ARCHAUTODIR)\.exists

	-@$(CHMOD) $(PERM_RWX) $(INST_ARCHAUTODIR)

config :: $(INST_MAN3DIR)\.exists
	@$(NOOP)


$(INST_MAN3DIR)\.exists :: D:\perl\5.6.0\lib\MSWin32-x86-multi-thread\CORE\perl.h
	@$(MKPATH) $(INST_MAN3DIR)
	@$(EQUALIZE_TIMESTAMP) D:\perl\5.6.0\lib\MSWin32-x86-multi-thread\CORE\perl.h $(INST_MAN3DIR)\.exists

	-@$(CHMOD) $(PERM_RWX) $(INST_MAN3DIR)

help:
	perldoc ExtUtils::MakeMaker

Version_check:
	@$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
		-MExtUtils::MakeMaker=Version_check \
		-e "Version_check('$(MM_VERSION)')"


# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	@$(NOOP)


# --- MakeMaker dlsyms section:

Wingraph.def: Makefile.PL
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -MExtUtils::Mksymlists \
     -e "Mksymlists('NAME' => 'Win32::Wingraph', 'DLBASE' => '$(BASEEXT)', 'DL_FUNCS' => {  }, 'FUNCLIST' => [], 'IMPORTS' => {  }, 'DL_VARS' => []);"


# --- MakeMaker dynamic section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make dynamic"
#dynamic :: Makefile $(INST_DYNAMIC) $(INST_BOOT) $(INST_PM)
dynamic :: Makefile $(INST_DYNAMIC) $(INST_BOOT)
	@$(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP = Wingraph.bs

# As Mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BOOTSTRAP): Makefile  $(INST_ARCHAUTODIR)\.exists
	@echo "Running Mkbootstrap for $(NAME) ($(BSLOADLIBS))"
	@$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" \
		-MExtUtils::Mkbootstrap \
		-e "Mkbootstrap('$(BASEEXT)','$(BSLOADLIBS)');"
	@$(TOUCH) $(BOOTSTRAP)
	$(CHMOD) 644 $@

$(INST_BOOT): $(BOOTSTRAP) $(INST_ARCHAUTODIR)\.exists
	@$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e rm_rf $(INST_BOOT)
	-$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e cp $(BOOTSTRAP) $(INST_BOOT)
	$(CHMOD) 644 $@


# --- MakeMaker dynamic_lib section:

# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
OTHERLDFLAGS = 
INST_DYNAMIC_DEP = 

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP) $(INST_ARCHAUTODIR)\.exists $(EXPORT_LIST) $(PERL_ARCHIVE) $(INST_DYNAMIC_DEP)
	$(LD) -out:$@ $(LDDLFLAGS) $(LDFROM) $(OTHERLDFLAGS) $(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) -def:$(EXPORT_LIST)
	$(CHMOD) 755 $@


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
#static :: Makefile $(INST_STATIC) $(INST_PM)
static :: Makefile $(INST_STATIC)
	@$(NOOP)


# --- MakeMaker static_lib section:

$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)\.exists
	$(RM_RF) $@
	$(AR) -out:$@ $(OBJECT)
	@echo "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)\extralibs.ld
	$(CHMOD) 755 $@


# --- MakeMaker htmlifypods section:

htmlifypods : pure_all
	@$(NOOP)


# --- MakeMaker manifypods section:

manifypods :
	@$(NOOP)


# --- MakeMaker processPL section:


# --- MakeMaker installbin section:


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	-$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e rm_rf Wingraph.c ./blib $(MAKE_APERL_FILE) $(INST_ARCHAUTODIR)/extralibs.all perlmain.c mon.out core core.*perl.*.? *perl.core so_locations pm_to_blib *~ */*~ */*/*~ *$(OBJ_EXT) *$(LIB_EXT) perl.exe $(BOOTSTRAP) $(BASEEXT).bso $(BASEEXT).def $(BASEEXT).exp
	-$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e mv Makefile Makefile.old $(DEV_NULL)


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e rm_rf $(INST_AUTODIR) $(INST_ARCHAUTODIR)
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e rm_f $(INST_DYNAMIC) $(INST_BOOT)
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e rm_f $(INST_STATIC)
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e rm_f $(INST_LIBDIR)\NPRG.pm $(INST_LIBDIR)\Wingraph.pm
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e rm_rf Makefile Makefile.old


# --- MakeMaker dist_basics section skipped.

# --- MakeMaker dist_core section skipped.

# --- MakeMaker dist_dir section skipped.

# --- MakeMaker dist_test section skipped.

# --- MakeMaker dist_ci section skipped.

# --- MakeMaker install section skipped.

# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE:
	@$(NOOP)


# --- MakeMaker perldepend section:

PERL_HDRS = \
	$(PERL_INC)/EXTERN.h		\
	$(PERL_INC)/INTERN.h		\
	$(PERL_INC)/XSUB.h		\
	$(PERL_INC)/av.h		\
	$(PERL_INC)/cc_runtime.h	\
	$(PERL_INC)/config.h		\
	$(PERL_INC)/cop.h		\
	$(PERL_INC)/cv.h		\
	$(PERL_INC)/dosish.h		\
	$(PERL_INC)/embed.h		\
	$(PERL_INC)/embedvar.h		\
	$(PERL_INC)/fakethr.h		\
	$(PERL_INC)/form.h		\
	$(PERL_INC)/gv.h		\
	$(PERL_INC)/handy.h		\
	$(PERL_INC)/hv.h		\
	$(PERL_INC)/intrpvar.h		\
	$(PERL_INC)/iperlsys.h		\
	$(PERL_INC)/keywords.h		\
	$(PERL_INC)/mg.h		\
	$(PERL_INC)/nostdio.h		\
	$(PERL_INC)/objXSUB.h		\
	$(PERL_INC)/op.h		\
	$(PERL_INC)/opcode.h		\
	$(PERL_INC)/opnames.h		\
	$(PERL_INC)/patchlevel.h	\
	$(PERL_INC)/perl.h		\
	$(PERL_INC)/perlapi.h		\
	$(PERL_INC)/perlio.h		\
	$(PERL_INC)/perlsdio.h		\
	$(PERL_INC)/perlsfio.h		\
	$(PERL_INC)/perlvars.h		\
	$(PERL_INC)/perly.h		\
	$(PERL_INC)/pp.h		\
	$(PERL_INC)/pp_proto.h		\
	$(PERL_INC)/proto.h		\
	$(PERL_INC)/regcomp.h		\
	$(PERL_INC)/regexp.h		\
	$(PERL_INC)/regnodes.h		\
	$(PERL_INC)/scope.h		\
	$(PERL_INC)/sv.h		\
	$(PERL_INC)/thrdvar.h		\
	$(PERL_INC)/thread.h		\
	$(PERL_INC)/unixish.h		\
	$(PERL_INC)/utf8.h		\
	$(PERL_INC)/util.h		\
	$(PERL_INC)/warnings.h

$(OBJECT) : $(PERL_HDRS)

Wingraph.c : $(XSUBPPDEPS)


# --- MakeMaker makefile section:

$(OBJECT) : $(FIRST_MAKEFILE)

# We take a very conservative approach here, but it\'s worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
Makefile : Makefile.PL $(CONFIGDEP)
	@echo "Makefile out-of-date with respect to $?"
	@echo "Cleaning current config before rebuilding Makefile..."
	-@$(RM_F) Makefile.old
	-@$(MV) Makefile Makefile.old
	-$(MAKE) -f Makefile.old clean $(DEV_NULL) || $(NOOP)
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL 
	@echo "==> Your Makefile has been rebuilt. <=="
	@echo "==> Please rerun the make command.  <=="
	false

# To change behavior to :: would be nice, but would break Tk b9.02
# so you find such a warning below the dist target.
#Makefile :: $(VERSION_FROM)
#	@echo "Warning: Makefile possibly out of date with $(VERSION_FROM)"


# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = ..\perl
FULLPERL      = D:\perl\5.6.0\bin\perl.exe


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = 
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)

test :: $(TEST_TYPE)
	@echo 'No tests defined for $(NAME) extension.'

test_dynamic :: pure_all

testdb_dynamic :: pure_all
	$(FULLPERL) $(TESTDB_SW) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(TEST_FILE)

test_ : test_dynamic

test_static :: pure_all $(MAP_TARGET)

testdb_static :: pure_all $(MAP_TARGET)
	./$(MAP_TARGET) $(TESTDB_SW) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(TEST_FILE)



# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd:
	@$(PERL) -e "print qq{<SOFTPKG NAME=\"Win32-Wingraph\" VERSION=\"0,2,0,0\">\n}. qq{\t<TITLE>Win32-Wingraph</TITLE>\n}. qq{\t<ABSTRACT></ABSTRACT>\n}. qq{\t<AUTHOR></AUTHOR>\n}. qq{\t<IMPLEMENTATION>\n}. qq{\t\t<OS NAME=\"$(OSNAME)\" />\n}. qq{\t\t<ARCHITECTURE NAME=\"MSWin32-x86-multi-thread\" />\n}. qq{\t\t<CODEBASE HREF=\"\" />\n}. qq{\t</IMPLEMENTATION>\n}. qq{</SOFTPKG>\n}" > Win32-Wingraph.ppd

# --- MakeMaker pm_to_blib section:

pm_to_blib: $(TO_INST_PM)
	@$(PERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" \
	"-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -MExtUtils::Install \
        -e "pm_to_blib(qw[ <<pmfiles.dat ],'$(INST_LIB)\auto')"
	
$(PM_TO_BLIB)
<<
	@$(TOUCH) $@


# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:


# End.
