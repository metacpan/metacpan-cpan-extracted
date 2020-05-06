# This Makefile is for the DBD::mysql extension to perl.
#
# It was generated automatically by MakeMaker version
# 7.34 (Revision: 73400) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     ABSTRACT => q[A MySQL driver for the Perl5 Database Interface (DBI)]
#     AUTHOR => [q[Patrick Galbraith <patg@patg.net>]]
#     BUILD_REQUIRES => {  }
#     C => [q[dbdimp.c], q[mysql.c]]
#     CONFIGURE_REQUIRES => { DBI=>q[1.609], Data::Dumper=>q[0] }
#     INC => q[-I$(DBI_INSTARCH_DIR) -I/usr/local/opt/mysql-client/include/mysql -DDBD_MYSQL_WITH_SSL -DDBD_MYSQL_INSERT_ID_IS_GOOD -g ]
#     LIBS => q[-L/usr/local/opt/openssl@1.1/lib -L/usr/local/opt/mysql-client/lib  -lmysqlclient]
#     LICENSE => q[perl]
#     META_MERGE => { dynamic_config=>q[0], meta-spec=>{ version=>q[2] }, resources=>{ bugtracker=>{ web=>q[https://github.com/perl5-dbi/DBD-mysql/issues] }, homepage=>q[http://dbi.perl.org/], license=>[q[http://dev.perl.org/licenses/]], repository=>{ type=>q[git], url=>q[https://github.com/perl5-dbi/DBD-mysql.git], web=>q[https://github.com/perl5-dbi/DBD-mysql] }, x_IRC=>q[irc://irc.perl.org/#dbi], x_MailingList=>q[mailto:dbi-dev@perl.org] }, x_contributors=>[q[Alexandr Ciornii <alexchorny@gmail.com>], q[Alexey Molchanov <alexey.molchanov@portaone.com>], q[Amiri Barksdale at Home <amiri@roosterpirates.com>], q[Andrew Miller <ikari7789@yahoo.com>], q[Aran Deltac <bluefeet@gmail.com>], q[Bernt M. Johnsen <bernt.johnsen@oracle.com>], q[Chase Whitener <chase.whitener@infotechfl.com>], q[Chip Salzenberg <chip@topsy.com>], q[Chris Hammond <chrishammond@ymail.com>], q[Chris Weyl <cweyl@alumni.drew.edu>], q[Christian Walde <walde.christian@googlemail.com>], q[Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>], q[Daisuke Murase <typester@cpan.org>], q[Damyan Ivanov <dmn@debian.org>], q[Dan Book <grinnz@gmail.com>], q[Daniël van Eeden <daniel.vaneeden@booking.com>], q[Dave Lambley <davel@isosceles.(none)>], q[David Farrell <davidnmfarrell@gmail.com>], q[David Steinbrunner <dsteinbrunner@pobox.com>], q[Giovanni Bechis <giovanni@bigio.snb.it>], q[Graham Ollis <plicease@cpan.org>], q[H.Merijn Brand - Tux <h.m.brand@xs4all.nl>], q[Hanno <hanno@gentoo.org>], q[James McCoy <jamessan@jamessan.com>], q[Jim Winstead <jimw@trainedmonkey.com>], q[Juergen Weigert <jw@suse.com>], q[Kenny Gryp <kenny.gryp@percona.com>], q[Lu Shengliang <lushl9301@gmail.com>], q[Masahiro Chiba <chiba@everqueue.com>], q[Matthew Horsfall (alh) <WolfSage@gmail.com>], q[Michiel Beijen <michiel.beijen@gmail.com>], q[Mike Pomraning <mjp@pilcrow.madison.wi.us>], q[Mohammad S Anwar <mohammad.anwar@yahoo.com>], q[Pali <pali@cpan.org>], q[Patrick Galbraith <patg@patg.net>], q[Perlover <perlover@perlover.com>], q[Petr Písař <ppisar@redhat.com>], q[Reini Urban <rurban@cpanel.net>], q[Rob Hoelz <rhoelz@inoc.com>], q[Rob Van Dam <rvandam00@gmail.com>], q[Rudy Lippan <rlippan@remotelinux.com>], q[Scimon <simon.proctor@gmail.com>], q[Sergey Zhuravlev <zhurs@ya.ru>], q[Sergiy Borodych <Sergiy.Borodych@gmail.com>], q[Sharif Nassar <mrwacky42+github@gmail.com>], q[Steffen Mueller <smueller@cpan.org>], q[Steven Hartland <steven.hartland@multiplay.co.uk>], q[Taro Kobayashi <9re.3000@gmail.com>], q[Tatsuhiko Miyagawa <miyagawa@bulknews.net>], q[Tim Mullin <tim@cpanel.net>], q[Ville Skyttä <ville.skytta@iki.fi>], q[Vladimir Marek <vlmarek@volny.cz>], q[katyavoid <katyavoid@gmail.com>], q[kmx <kmx@cpan.org>], q[tokuhirom <tokuhirom@gmail.com>], q[zefram <zefram@fysh.org>], q[zentooo <ankerasoy@gmail.com>]] }
#     MIN_PERL_VERSION => q[5.008001]
#     NAME => q[DBD::mysql]
#     OBJECT => q[$(O_FILES)]
#     PREREQ_PM => { DBI=>q[1.609], Test::Deep=>q[0], Test::Simple=>q[0.90], Time::HiRes=>q[0] }
#     TEST_REQUIRES => { Test::Deep=>q[0], Test::Simple=>q[0.90], Time::HiRes=>q[0] }
#     VERSION_FROM => q[lib/DBD/mysql.pm]
#     XS => { mysql.xs=>q[mysql.c] }
#     clean => { FILES=>q[*.xsi] }
#     dist => { COMPRESS=>q[gzip -9f], DIST_DEFAULT=>q[all tardist], SUFFIX=>q[.gz] }
#     realclean => { FILES=>q[t/mysql.mtest] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/darwin-thread-multi-2level/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = cc
CCCDLFLAGS =  
CCDLFLAGS =  
DLEXT = bundle
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = cc
LDDLFLAGS =  -mmacosx-version-min=10.14 -bundle -undefined dynamic_lookup -L/usr/local/lib -fstack-protector-strong
LDFLAGS =  -mmacosx-version-min=10.14 -fstack-protector-strong -L/usr/local/lib
LIBC = 
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = darwin
OSVERS = 18.6.0
RANLIB = ranlib
SITELIBEXP = /usr/local/Cellar/perl/5.30.0/lib/perl5/site_perl/5.30.0
SITEARCHEXP = /usr/local/Cellar/perl/5.30.0/lib/perl5/site_perl/5.30.0/darwin-thread-multi-2level
SO = dylib
VENDORARCHEXP = 
VENDORLIBEXP = 


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = DBD::mysql
NAME_SYM = DBD_mysql
VERSION = 4.046
VERSION_MACRO = VERSION
VERSION_SYM = 4_046
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 4.046
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1
MAN3EXT = 3
INSTALLDIRS = site
DESTDIR = 
PREFIX = $(SITEPREFIX)
PERLPREFIX = /usr/local/Cellar/perl/5.30.0
SITEPREFIX = /usr/local/Cellar/perl/5.30.0
VENDORPREFIX = 
INSTALLPRIVLIB = /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = /usr/local/Cellar/perl/5.30.0/lib/perl5/site_perl/5.30.0
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = 
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/darwin-thread-multi-2level
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = /usr/local/Cellar/perl/5.30.0/lib/perl5/site_perl/5.30.0/darwin-thread-multi-2level
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = 
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = /usr/local/Cellar/perl/5.30.0/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = /usr/local/Cellar/perl/5.30.0/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = 
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = /usr/local/Cellar/perl/5.30.0/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = /usr/local/Cellar/perl/5.30.0/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = 
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = /usr/local/Cellar/perl/5.30.0/share/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = /usr/local/Cellar/perl/5.30.0/share/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = 
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = /usr/local/Cellar/perl/5.30.0/share/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = /usr/local/Cellar/perl/5.30.0/share/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = 
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0
PERL_ARCHLIB = /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/darwin-thread-multi-2level
PERL_ARCHLIBDEP = /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/darwin-thread-multi-2level
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/darwin-thread-multi-2level/CORE
PERL_INCDEP = /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/darwin-thread-multi-2level/CORE
PERL = "/usr/local/Cellar/perl/5.30.0/bin/perl"
FULLPERL = "/usr/local/Cellar/perl/5.30.0/bin/perl"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/ExtUtils/MakeMaker.pm
MM_VERSION  = 7.34
MM_REVISION = 73400

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = DBD/mysql
BASEEXT = mysql
PARENT_NAME = DBD
DLBASE = $(BASEEXT)
VERSION_FROM = lib/DBD/mysql.pm
INC = -I$(DBI_INSTARCH_DIR) -I/usr/local/opt/mysql-client/include/mysql -DDBD_MYSQL_WITH_SSL -DDBD_MYSQL_INSERT_ID_IS_GOOD -g 
OBJECT = $(O_FILES)
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = mysql.xs
C_FILES  = dbdimp.c \
	mysql.c
O_FILES  = dbdimp.o \
	mysql.o
H_FILES  = constants.h \
	dbdimp.h
MAN1PODS = 
MAN3PODS = lib/Bundle/DBD/mysql.pm \
	lib/DBD/mysql.pm \
	lib/DBD/mysql/INSTALL.pod

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIBDEP)$(DFSEP)Config.pm $(PERL_INCDEP)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)/DBD
INST_ARCHLIBDIR  = $(INST_ARCHLIB)/DBD

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = $(INST_ARCHAUTODIR)/$(BASEEXT)$(LIB_EXT)
INST_DYNAMIC     = $(INST_ARCHAUTODIR)/$(DLBASE).$(DLEXT)
INST_BOOT        = $(INST_ARCHAUTODIR)/$(BASEEXT).bs

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVEDEP    = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/Bundle/DBD/mysql.pm \
	lib/DBD/mysql.pm \
	lib/DBD/mysql/GetInfo.pm \
	lib/DBD/mysql/INSTALL.pod


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 7.34
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:

XSUBPPDIR = /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/ExtUtils
XSUBPP = "$(XSUBPPDIR)$(DFSEP)xsubpp"
XSUBPPRUN = $(PERLRUN) $(XSUBPP)
XSPROTOARG = 
XSUBPPDEPS = /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/ExtUtils/typemap /usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/ExtUtils$(DFSEP)xsubpp
XSUBPPARGS = -typemap '/usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/ExtUtils/typemap'
XSUBPP_EXTRA_ARGS =


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --
CP_NONEMPTY = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'cp_nonempty' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = COPY_EXTENDED_ATTRIBUTES_DISABLE=1 COPYFILE_DISABLE=1 tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip -9f
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = all tardist
DISTNAME = DBD-mysql
DISTVNAME = DBD-mysql-4.046


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:

CCFLAGS = -fno-common -DPERL_DARWIN -mmacosx-version-min=10.14 -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include -DPERL_USE_SAFE_PUTENV
OPTIMIZE = -O3
PERLTYPE = 
MPOLLUTE = 


# --- MakeMaker const_loadlibs section:

# DBD::mysql might depend on some other libraries:
# See ExtUtils::Liblist for details
#
EXTRALIBS = -L/usr/local/opt/openssl@1.1/lib -L/usr/local/opt/mysql-client/lib -lmysqlclient
LDLOADLIBS = -L/usr/local/opt/openssl@1.1/lib -L/usr/local/opt/mysql-client/lib -lmysqlclient
BSLOADLIBS = 
LD_RUN_PATH = /usr/local/opt/mysql-client/lib


# --- MakeMaker const_cccmd section:
CCCMD = $(CC) -c $(PASTHRU_INC) $(INC) \
	$(CCFLAGS) $(OPTIMIZE) \
	$(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION) \
	$(XS_DEFINE_VERSION)

# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	OPTIMIZE="$(OPTIMIZE)"\
	PREFIX="$(PREFIX)"\
	PASTHRU_DEFINE='$(DEFINE) $(PASTHRU_DEFINE)'\
	PASTHRU_INC='-I$(DBI_INSTARCH_DIR) -I/usr/local/opt/mysql-client/include/mysql -DDBD_MYSQL_WITH_SSL -DDBD_MYSQL_INSERT_ID_IS_GOOD -g  $(PASTHRU_INC)'


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir pure_all subdirs clean_subdirs makemakerdflt manifypods realclean_subdirs subdirs_dynamic subdirs_pure_nolink subdirs_static subdirs-test_dynamic subdirs-test_static test_dynamic test_static



# --- MakeMaker c_o section:

.c.i:
	cc  -E -c $(PASTHRU_INC) $(INC) \
	$(CCFLAGS) $(OPTIMIZE) \
	$(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION) \
	$(XS_DEFINE_VERSION) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.c > $*.i

.c.s :
	$(CCCMD) -S $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.c 

.c$(OBJ_EXT) :
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.c

.cpp$(OBJ_EXT) :
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.cpp

.cxx$(OBJ_EXT) :
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.cxx

.cc$(OBJ_EXT) :
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.cc

.C$(OBJ_EXT) :
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.C


# --- MakeMaker xs_c section:

.xs.c:
	$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $(XSUBPP_EXTRA_ARGS) $*.xs > $*.xsc
	$(MV) $*.xsc $*.c


# --- MakeMaker xs_o section:
.xs$(OBJ_EXT) :
	$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.xsc
	$(MV) $*.xsc $*.c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.c 


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)

pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

$(O_FILES) : $(H_FILES)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: dynamic
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic_bs section:
BOOTSTRAP = $(BASEEXT).bs

# As Mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BASEEXT).bs : $(FIRST_MAKEFILE) $(BOOTDEP)
	$(NOECHO) $(ECHO) "Running Mkbootstrap for $(BASEEXT) ($(BSLOADLIBS))"
	$(NOECHO) $(PERLRUN) \
		"-MExtUtils::Mkbootstrap" \
		-e "Mkbootstrap('$(BASEEXT)','$(BSLOADLIBS)');"
	$(NOECHO) $(TOUCH) "$(BASEEXT).bs"
	$(CHMOD) $(PERM_RW) "$(BASEEXT).bs"

$(INST_ARCHAUTODIR)/$(BASEEXT).bs : $(BASEEXT).bs $(INST_ARCHAUTODIR)$(DFSEP).exists
	$(NOECHO) $(RM_RF) $(INST_ARCHAUTODIR)/$(BASEEXT).bs
	- $(CP_NONEMPTY) $(BASEEXT).bs $(INST_ARCHAUTODIR)/$(BASEEXT).bs $(PERM_RW)


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) config $(INST_BOOT) $(INST_DYNAMIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_lib section:
# This section creates the dynamically loadable objects from relevant
# objects and possibly $(MYEXTLIB).
ARMAYBE = :
OTHERLDFLAGS = 
INST_DYNAMIC_DEP = 
INST_DYNAMIC_FIX = 

$(INST_DYNAMIC) : $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)$(DFSEP).exists $(EXPORT_LIST) $(PERL_ARCHIVEDEP) $(PERL_ARCHIVE_AFTER) $(INST_DYNAMIC_DEP) 
	$(RM_F) $@
	LD_RUN_PATH="$(LD_RUN_PATH)" $(LD)  $(LDDLFLAGS)  $(LDFROM) $(OTHERLDFLAGS) -o $@ $(MYEXTLIB) \
	  $(PERL_ARCHIVE) $(LDLOADLIBS) $(PERL_ARCHIVE_AFTER) $(EXPORT_LIST) \
	  $(INST_DYNAMIC_FIX)
	$(CHMOD) $(PERM_RWX) $@


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:
$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)$(DFSEP).exists
	$(RM_F) "$@"
	$(FULL_AR) $(AR_STATIC_ARGS) "$@" $(OBJECT)
	$(RANLIB) "$@"
	$(CHMOD) $(PERM_RWX) $@
	$(NOECHO) $(ECHO) "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)$(DFSEP)extralibs.ld


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all config  \
	lib/Bundle/DBD/mysql.pm \
	lib/DBD/mysql.pm \
	lib/DBD/mysql/INSTALL.pod
	$(NOECHO) $(POD2MAN) --section=3 --perm_rw=$(PERM_RW) -u \
	  lib/Bundle/DBD/mysql.pm $(INST_MAN3DIR)/Bundle::DBD::mysql.$(MAN3EXT) \
	  lib/DBD/mysql.pm $(INST_MAN3DIR)/DBD::mysql.$(MAN3EXT) \
	  lib/DBD/mysql/INSTALL.pod $(INST_MAN3DIR)/DBD::mysql::INSTALL.$(MAN3EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  $(BASEEXT).bso $(BASEEXT).def \
	  $(BASEEXT).exp $(BASEEXT).x \
	  $(BOOTSTRAP) $(INST_ARCHAUTODIR)/extralibs.all \
	  $(INST_ARCHAUTODIR)/extralibs.ld $(MAKE_APERL_FILE) \
	  *$(LIB_EXT) *$(OBJ_EXT) \
	  *perl.core MYMETA.json \
	  MYMETA.yml blibdirs.ts \
	  core core.*perl.*.? \
	  core.[0-9] core.[0-9][0-9] \
	  core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] \
	  core.[0-9][0-9][0-9][0-9][0-9] lib$(BASEEXT).def \
	  mon.out mysql.base \
	  mysql.bs mysql.bso \
	  mysql.c mysql.def \
	  mysql.exp mysql.o \
	  mysql_def.old perl \
	  perl$(EXE_EXT) perl.exe \
	  perlmain.c pm_to_blib \
	  pm_to_blib.ts so_locations \
	  tmon.out 
	- $(RM_RF) \
	  *.xsi blib 
	  $(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
# so clean is forced to complete before realclean_subdirs runs
realclean_subdirs : clean
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge :: realclean_subdirs
	- $(RM_F) \
	  $(FIRST_MAKEFILE) $(MAKEFILE_OLD) \
	  $(OBJECT) 
	- $(RM_RF) \
	  $(DISTVNAME) t/mysql.mtest 


# --- MakeMaker metafile section:
metafile : create_distdir
	$(NOECHO) $(ECHO) Generating META.yml
	$(NOECHO) $(ECHO) '---' > META_new.yml
	$(NOECHO) $(ECHO) 'abstract: '\''A MySQL driver for the Perl5 Database Interface (DBI)'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'author:' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Patrick Galbraith <patg@patg.net>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'build_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::Deep: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::Simple: '\''0.90'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Time::HiRes: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'configure_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  DBI: '\''1.609'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Data::Dumper: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'dynamic_config: 0' >> META_new.yml
	$(NOECHO) $(ECHO) 'generated_by: '\''ExtUtils::MakeMaker version 7.34, CPAN::Meta::Converter version 2.150010'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'license: perl' >> META_new.yml
	$(NOECHO) $(ECHO) 'meta-spec:' >> META_new.yml
	$(NOECHO) $(ECHO) '  url: http://module-build.sourceforge.net/META-spec-v1.4.html' >> META_new.yml
	$(NOECHO) $(ECHO) '  version: '\''1.4'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'name: DBD-mysql' >> META_new.yml
	$(NOECHO) $(ECHO) 'no_index:' >> META_new.yml
	$(NOECHO) $(ECHO) '  directory:' >> META_new.yml
	$(NOECHO) $(ECHO) '    - t' >> META_new.yml
	$(NOECHO) $(ECHO) '    - inc' >> META_new.yml
	$(NOECHO) $(ECHO) 'requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  DBI: '\''1.609'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  perl: '\''5.008001'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'resources:' >> META_new.yml
	$(NOECHO) $(ECHO) '  IRC: irc://irc.perl.org/#dbi' >> META_new.yml
	$(NOECHO) $(ECHO) '  MailingList: mailto:dbi-dev@perl.org' >> META_new.yml
	$(NOECHO) $(ECHO) '  bugtracker: https://github.com/perl5-dbi/DBD-mysql/issues' >> META_new.yml
	$(NOECHO) $(ECHO) '  homepage: http://dbi.perl.org/' >> META_new.yml
	$(NOECHO) $(ECHO) '  license: http://dev.perl.org/licenses/' >> META_new.yml
	$(NOECHO) $(ECHO) '  repository: https://github.com/perl5-dbi/DBD-mysql.git' >> META_new.yml
	$(NOECHO) $(ECHO) 'version: '\''4.046'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'x_contributors:' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Alexandr Ciornii <alexchorny@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Alexey Molchanov <alexey.molchanov@portaone.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Amiri Barksdale at Home <amiri@roosterpirates.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Andrew Miller <ikari7789@yahoo.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Aran Deltac <bluefeet@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Bernt M. Johnsen <bernt.johnsen@oracle.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Chase Whitener <chase.whitener@infotechfl.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Chip Salzenberg <chip@topsy.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Chris Hammond <chrishammond@ymail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Chris Weyl <cweyl@alumni.drew.edu>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Christian Walde <walde.christian@googlemail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Daisuke Murase <typester@cpan.org>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Damyan Ivanov <dmn@debian.org>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Dan Book <grinnz@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Daniël van Eeden <daniel.vaneeden@booking.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Dave Lambley <davel@isosceles.(none)>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''David Farrell <davidnmfarrell@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''David Steinbrunner <dsteinbrunner@pobox.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Giovanni Bechis <giovanni@bigio.snb.it>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Graham Ollis <plicease@cpan.org>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''H.Merijn Brand - Tux <h.m.brand@xs4all.nl>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Hanno <hanno@gentoo.org>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''James McCoy <jamessan@jamessan.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Jim Winstead <jimw@trainedmonkey.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Juergen Weigert <jw@suse.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Kenny Gryp <kenny.gryp@percona.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Lu Shengliang <lushl9301@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Masahiro Chiba <chiba@everqueue.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Matthew Horsfall (alh) <WolfSage@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Michiel Beijen <michiel.beijen@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Mike Pomraning <mjp@pilcrow.madison.wi.us>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Mohammad S Anwar <mohammad.anwar@yahoo.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Pali <pali@cpan.org>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Patrick Galbraith <patg@patg.net>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Perlover <perlover@perlover.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Petr Písař <ppisar@redhat.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Reini Urban <rurban@cpanel.net>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Rob Hoelz <rhoelz@inoc.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Rob Van Dam <rvandam00@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Rudy Lippan <rlippan@remotelinux.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Scimon <simon.proctor@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Sergey Zhuravlev <zhurs@ya.ru>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Sergiy Borodych <Sergiy.Borodych@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Sharif Nassar <mrwacky42+github@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Steffen Mueller <smueller@cpan.org>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Steven Hartland <steven.hartland@multiplay.co.uk>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Taro Kobayashi <9re.3000@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Tatsuhiko Miyagawa <miyagawa@bulknews.net>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Tim Mullin <tim@cpanel.net>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Ville Skyttä <ville.skytta@iki.fi>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Vladimir Marek <vlmarek@volny.cz>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''katyavoid <katyavoid@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''kmx <kmx@cpan.org>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''tokuhirom <tokuhirom@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''zefram <zefram@fysh.org>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''zentooo <ankerasoy@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'x_serialization_backend: '\''CPAN::Meta::YAML version 0.018'\''' >> META_new.yml
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) Generating META.json
	$(NOECHO) $(ECHO) '{' > META_new.json
	$(NOECHO) $(ECHO) '   "abstract" : "A MySQL driver for the Perl5 Database Interface (DBI)",' >> META_new.json
	$(NOECHO) $(ECHO) '   "author" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "Patrick Galbraith <patg@patg.net>"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "dynamic_config" : 0,' >> META_new.json
	$(NOECHO) $(ECHO) '   "generated_by" : "ExtUtils::MakeMaker version 7.34, CPAN::Meta::Converter version 2.150010",' >> META_new.json
	$(NOECHO) $(ECHO) '   "license" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "perl_5"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "meta-spec" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",' >> META_new.json
	$(NOECHO) $(ECHO) '      "version" : 2' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "name" : "DBD-mysql",' >> META_new.json
	$(NOECHO) $(ECHO) '   "no_index" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "directory" : [' >> META_new.json
	$(NOECHO) $(ECHO) '         "t",' >> META_new.json
	$(NOECHO) $(ECHO) '         "inc"' >> META_new.json
	$(NOECHO) $(ECHO) '      ]' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "prereqs" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "build" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "configure" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "DBI" : "1.609",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Data::Dumper" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "runtime" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "DBI" : "1.609",' >> META_new.json
	$(NOECHO) $(ECHO) '            "perl" : "5.008001"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "test" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::Deep" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::Simple" : "0.90",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Time::HiRes" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      }' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "release_status" : "stable",' >> META_new.json
	$(NOECHO) $(ECHO) '   "resources" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "bugtracker" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "web" : "https://github.com/perl5-dbi/DBD-mysql/issues"' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "homepage" : "http://dbi.perl.org/",' >> META_new.json
	$(NOECHO) $(ECHO) '      "license" : [' >> META_new.json
	$(NOECHO) $(ECHO) '         "http://dev.perl.org/licenses/"' >> META_new.json
	$(NOECHO) $(ECHO) '      ],' >> META_new.json
	$(NOECHO) $(ECHO) '      "repository" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "type" : "git",' >> META_new.json
	$(NOECHO) $(ECHO) '         "url" : "https://github.com/perl5-dbi/DBD-mysql.git",' >> META_new.json
	$(NOECHO) $(ECHO) '         "web" : "https://github.com/perl5-dbi/DBD-mysql"' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "x_IRC" : "irc://irc.perl.org/#dbi",' >> META_new.json
	$(NOECHO) $(ECHO) '      "x_MailingList" : "mailto:dbi-dev@perl.org"' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "version" : "4.046",' >> META_new.json
	$(NOECHO) $(ECHO) '   "x_contributors" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "Alexandr Ciornii <alexchorny@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Alexey Molchanov <alexey.molchanov@portaone.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Amiri Barksdale at Home <amiri@roosterpirates.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Andrew Miller <ikari7789@yahoo.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Aran Deltac <bluefeet@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Bernt M. Johnsen <bernt.johnsen@oracle.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Chase Whitener <chase.whitener@infotechfl.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Chip Salzenberg <chip@topsy.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Chris Hammond <chrishammond@ymail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Chris Weyl <cweyl@alumni.drew.edu>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Christian Walde <walde.christian@googlemail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Daisuke Murase <typester@cpan.org>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Damyan Ivanov <dmn@debian.org>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Dan Book <grinnz@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Daniël van Eeden <daniel.vaneeden@booking.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Dave Lambley <davel@isosceles.(none)>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "David Farrell <davidnmfarrell@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "David Steinbrunner <dsteinbrunner@pobox.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Giovanni Bechis <giovanni@bigio.snb.it>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Graham Ollis <plicease@cpan.org>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "H.Merijn Brand - Tux <h.m.brand@xs4all.nl>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Hanno <hanno@gentoo.org>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "James McCoy <jamessan@jamessan.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Jim Winstead <jimw@trainedmonkey.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Juergen Weigert <jw@suse.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Kenny Gryp <kenny.gryp@percona.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Lu Shengliang <lushl9301@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Masahiro Chiba <chiba@everqueue.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Matthew Horsfall (alh) <WolfSage@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Michiel Beijen <michiel.beijen@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Mike Pomraning <mjp@pilcrow.madison.wi.us>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Mohammad S Anwar <mohammad.anwar@yahoo.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Pali <pali@cpan.org>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Patrick Galbraith <patg@patg.net>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Perlover <perlover@perlover.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Petr Písař <ppisar@redhat.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Reini Urban <rurban@cpanel.net>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Rob Hoelz <rhoelz@inoc.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Rob Van Dam <rvandam00@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Rudy Lippan <rlippan@remotelinux.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Scimon <simon.proctor@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Sergey Zhuravlev <zhurs@ya.ru>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Sergiy Borodych <Sergiy.Borodych@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Sharif Nassar <mrwacky42+github@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Steffen Mueller <smueller@cpan.org>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Steven Hartland <steven.hartland@multiplay.co.uk>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Taro Kobayashi <9re.3000@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Tatsuhiko Miyagawa <miyagawa@bulknews.net>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Tim Mullin <tim@cpanel.net>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Ville Skyttä <ville.skytta@iki.fi>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "Vladimir Marek <vlmarek@volny.cz>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "katyavoid <katyavoid@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "kmx <kmx@cpan.org>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "tokuhirom <tokuhirom@gmail.com>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "zefram <zefram@fysh.org>",' >> META_new.json
	$(NOECHO) $(ECHO) '      "zentooo <ankerasoy@gmail.com>"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "x_serialization_backend" : "JSON::PP version 4.02"' >> META_new.json
	$(NOECHO) $(ECHO) '}' >> META_new.json
	-$(NOECHO) $(MV) META_new.json $(DISTVNAME)/META.json


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(ABSPERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	  -e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';' --

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)_uu'

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)'
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).zip'
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).shar'
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir distmeta 
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:
ci :
	$(ABSPERLRUN) -MExtUtils::Manifest=maniread -e '@all = sort keys %{ maniread() };' \
	  -e 'print(qq{Executing $(CI) @all\n});' \
	  -e 'system(qq{$(CI) @all}) == 0 or die $$!;' \
	  -e 'print(qq{Executing $(RCS_LABEL) ...\n});' \
	  -e 'system(qq{$(RCS_LABEL) @all}) == 0 or die $$!;' --


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
	  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.yml to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
	  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.json to MANIFEST: $${'\''@'\''}"' --



# --- MakeMaker distsignature section:
distsignature : distmeta
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section:

install :: pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLARCHLIB)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLPRIVLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLARCHLIB)" \
		"$(INST_BIN)" "$(DESTINSTALLBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(SITEARCHEXP)/auto/$(FULLEXT)"


pure_site_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLSITELIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLSITEARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLSITEBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSITESCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLSITEMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLSITEMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(PERL_ARCHLIB)/auto/$(FULLEXT)"

pure_vendor_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLVENDORARCH)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLVENDORLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLVENDORARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLVENDORBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLVENDORSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLVENDORMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLVENDORMAN3DIR)"


doc_perl_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)/perllocal.pod"

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)/perllocal.pod"

doc_vendor_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)/perllocal.pod"


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) "$(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist"

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist"

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) "$(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist"


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:
PERL_HDRS = \
        $(PERL_INCDEP)/EXTERN.h            \
        $(PERL_INCDEP)/INTERN.h            \
        $(PERL_INCDEP)/XSUB.h            \
        $(PERL_INCDEP)/av.h            \
        $(PERL_INCDEP)/bitcount.h            \
        $(PERL_INCDEP)/charclass_invlists.h            \
        $(PERL_INCDEP)/config.h            \
        $(PERL_INCDEP)/cop.h            \
        $(PERL_INCDEP)/cv.h            \
        $(PERL_INCDEP)/dosish.h            \
        $(PERL_INCDEP)/dquote_inline.h            \
        $(PERL_INCDEP)/ebcdic_tables.h            \
        $(PERL_INCDEP)/embed.h            \
        $(PERL_INCDEP)/embedvar.h            \
        $(PERL_INCDEP)/fakesdio.h            \
        $(PERL_INCDEP)/feature.h            \
        $(PERL_INCDEP)/form.h            \
        $(PERL_INCDEP)/git_version.h            \
        $(PERL_INCDEP)/gv.h            \
        $(PERL_INCDEP)/handy.h            \
        $(PERL_INCDEP)/hv.h            \
        $(PERL_INCDEP)/hv_func.h            \
        $(PERL_INCDEP)/hv_macro.h            \
        $(PERL_INCDEP)/inline.h            \
        $(PERL_INCDEP)/intrpvar.h            \
        $(PERL_INCDEP)/invlist_inline.h            \
        $(PERL_INCDEP)/iperlsys.h            \
        $(PERL_INCDEP)/keywords.h            \
        $(PERL_INCDEP)/l1_char_class_tab.h            \
        $(PERL_INCDEP)/malloc_ctl.h            \
        $(PERL_INCDEP)/metaconfig.h            \
        $(PERL_INCDEP)/mg.h            \
        $(PERL_INCDEP)/mg_data.h            \
        $(PERL_INCDEP)/mg_raw.h            \
        $(PERL_INCDEP)/mg_vtable.h            \
        $(PERL_INCDEP)/mydtrace.h            \
        $(PERL_INCDEP)/nostdio.h            \
        $(PERL_INCDEP)/op.h            \
        $(PERL_INCDEP)/op_reg_common.h            \
        $(PERL_INCDEP)/opcode.h            \
        $(PERL_INCDEP)/opnames.h            \
        $(PERL_INCDEP)/overload.h            \
        $(PERL_INCDEP)/pad.h            \
        $(PERL_INCDEP)/parser.h            \
        $(PERL_INCDEP)/patchlevel.h            \
        $(PERL_INCDEP)/perl.h            \
        $(PERL_INCDEP)/perl_inc_macro.h            \
        $(PERL_INCDEP)/perl_langinfo.h            \
        $(PERL_INCDEP)/perlapi.h            \
        $(PERL_INCDEP)/perlio.h            \
        $(PERL_INCDEP)/perliol.h            \
        $(PERL_INCDEP)/perlsdio.h            \
        $(PERL_INCDEP)/perlvars.h            \
        $(PERL_INCDEP)/perly.h            \
        $(PERL_INCDEP)/pp.h            \
        $(PERL_INCDEP)/pp_proto.h            \
        $(PERL_INCDEP)/proto.h            \
        $(PERL_INCDEP)/reentr.h            \
        $(PERL_INCDEP)/regcharclass.h            \
        $(PERL_INCDEP)/regcomp.h            \
        $(PERL_INCDEP)/regexp.h            \
        $(PERL_INCDEP)/regnodes.h            \
        $(PERL_INCDEP)/sbox32_hash.h            \
        $(PERL_INCDEP)/scope.h            \
        $(PERL_INCDEP)/stadtx_hash.h            \
        $(PERL_INCDEP)/sv.h            \
        $(PERL_INCDEP)/thread.h            \
        $(PERL_INCDEP)/time64.h            \
        $(PERL_INCDEP)/time64_config.h            \
        $(PERL_INCDEP)/uconfig.h            \
        $(PERL_INCDEP)/uni_keywords.h            \
        $(PERL_INCDEP)/unicode_constants.h            \
        $(PERL_INCDEP)/unixish.h            \
        $(PERL_INCDEP)/utf8.h            \
        $(PERL_INCDEP)/utfebcdic.h            \
        $(PERL_INCDEP)/util.h            \
        $(PERL_INCDEP)/uudmap.h            \
        $(PERL_INCDEP)/vutil.h            \
        $(PERL_INCDEP)/warnings.h            \
        $(PERL_INCDEP)/zaphod32_hash.h            

$(OBJECT) : $(PERL_HDRS)

mysql.c : $(XSUBPPDEPS)


# --- MakeMaker makefile section:

$(OBJECT) : $(FIRST_MAKEFILE)

# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = "/usr/local/Cellar/perl/5.30.0/bin/perl"
MAP_PERLINC   = "-Iblib/arch" "-Iblib/lib" "-I/usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0/darwin-thread-multi-2level" "-I/usr/local/Cellar/perl/5.30.0/lib/perl5/5.30.0"

$(MAP_TARGET) :: $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : static $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR="" \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:
TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/*.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)
	$(NOECHO) $(NOOP)

test :: $(TEST_TYPE)
	$(NOECHO) $(NOOP)

# Occasionally we may face this degenerate target:
test_ : test_dynamic
	$(NOECHO) $(NOOP)

subdirs-test_dynamic :: dynamic pure_all

test_dynamic :: subdirs-test_dynamic
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: dynamic pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

subdirs-test_static :: static pure_all

test_static :: subdirs-test_static $(MAP_TARGET)
	PERL_DL_NONLAZY=1 "/Users/jhthorsen/git/mojo-mysql/local/DBD-mysql/$(MAP_TARGET)" $(MAP_PERLINC) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_static :: static pure_all $(MAP_TARGET)
	PERL_DL_NONLAZY=1 "/Users/jhthorsen/git/mojo-mysql/local/DBD-mysql/$(MAP_TARGET)" $(MAP_PERLINC) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)



# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="DBD-mysql" VERSION="4.046">' > DBD-mysql.ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT>A MySQL driver for the Perl5 Database Interface (DBI)</ABSTRACT>' >> DBD-mysql.ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>Patrick Galbraith &lt;patg@patg.net&gt;</AUTHOR>' >> DBD-mysql.ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> DBD-mysql.ppd
	$(NOECHO) $(ECHO) '        <PERLCORE VERSION="5,008001,0,0" />' >> DBD-mysql.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="DBI::" VERSION="1.609" />' >> DBD-mysql.ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="darwin-thread-multi-2level-5.30" />' >> DBD-mysql.ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> DBD-mysql.ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> DBD-mysql.ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> DBD-mysql.ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/Bundle/DBD/mysql.pm' 'blib/lib/Bundle/DBD/mysql.pm' \
	  'lib/DBD/mysql.pm' 'blib/lib/DBD/mysql.pm' \
	  'lib/DBD/mysql/GetInfo.pm' 'blib/lib/DBD/mysql/GetInfo.pm' \
	  'lib/DBD/mysql/INSTALL.pod' 'blib/lib/DBD/mysql/INSTALL.pod' 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:

# here so even if top_targets is overridden, these will still be defined
# gmake will silently still work if any are .PHONY-ed but nmake won't

static ::
	$(NOECHO) $(NOOP)

dynamic ::
	$(NOECHO) $(NOOP)

config ::
	$(NOECHO) $(NOOP)


# --- MakeMaker postamble section:

# --- This section was generated by DBI::DBD::dbd_postamble()
DBI_INSTARCH_DIR=/usr/local/Cellar/perl/5.30.0/lib/perl5/site_perl/5.30.0/darwin-thread-multi-2level/auto/DBI
DBI_DRIVER_XST=/usr/local/Cellar/perl/5.30.0/lib/perl5/site_perl/5.30.0/darwin-thread-multi-2level/auto/DBI/Driver.xst

# The main dependency (technically correct but probably not used)
$(BASEEXT).c: $(BASEEXT).xsi

# This dependency is needed since MakeMaker uses the .xs.o rule
$(BASEEXT)$(OBJ_EXT): $(BASEEXT).xsi

$(BASEEXT).xsi: $(DBI_DRIVER_XST) /usr/local/Cellar/perl/5.30.0/lib/perl5/site_perl/5.30.0/darwin-thread-multi-2level/auto/DBI/Driver_xst.h
	$(PERL) -p -e "s/~DRIVER~/$(BASEEXT)/g" $(DBI_DRIVER_XST) > $(BASEEXT).xsi

# ---


# End.
