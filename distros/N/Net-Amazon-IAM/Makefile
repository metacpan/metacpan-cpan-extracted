# This Makefile is for the Net::Amazon::IAM extension to perl.
#
# It was generated automatically by MakeMaker version
# 6.66 (Revision: 66600) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     ABSTRACT => q[Perl interface to the Amazon Identity and Access Management.]
#     AUTHOR => [q[Igor Tsigankov <tsiganenok@gmail.com>]]
#     BUILD_REQUIRES => { ExtUtils::MakeMaker=>q[6.36] }
#     CONFIGURE_REQUIRES => {  }
#     DISTNAME => q[Net-Amazon-IAM]
#     LICENSE => q[perl]
#     NAME => q[Net::Amazon::IAM]
#     NO_META => q[1]
#     PREREQ_PM => { Data::Dumper=>q[0], Moose=>q[0], LWP::Protocol::https=>q[0], HTTP::Request::Common=>q[0], Params::Validate=>q[0], AWS::Signature4=>q[0], URI::Encode=>q[0], URI=>q[0], Carp=>q[0], ExtUtils::MakeMaker=>q[6.36], XML::Simple=>q[0], LWP::UserAgent=>q[0], POSIX=>q[0], JSON=>q[0] }
#     TEST_REQUIRES => {  }
#     VERSION => q[0.05]
#     VERSION_FROM => q[lib/Net/Amazon/IAM.pm]
#     dist => { PREOP=>q[$(PERL) -I. "-MModule::Install::Admin" -e "dist_preop(q($(DISTVNAME)))"] }
#     realclean => { FILES=>q[MYMETA.yml] }
#     test => { TESTS=>q[t/00-load.t t/boilerplate.t t/manifest.t t/pod-coverage.t t/pod.t] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /usr/lib/perl/5.18/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = cc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -Wl,-E
DLEXT = so
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = cc
LDDLFLAGS = -shared -L/usr/local/lib -fstack-protector
LDFLAGS =  -fstack-protector -L/usr/local/lib
LIBC = 
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 3.2.0-58-generic
RANLIB = :
SITELIBEXP = /usr/local/share/perl/5.18.2
SITEARCHEXP = /usr/local/lib/perl/5.18.2
SO = so
VENDORARCHEXP = /usr/lib/perl5
VENDORLIBEXP = /usr/share/perl5


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = Net::Amazon::IAM
NAME_SYM = Net_Amazon_IAM
VERSION = 0.05
VERSION_MACRO = VERSION
VERSION_SYM = 0_05
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 0.05
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1p
MAN3EXT = 3pm
INSTALLDIRS = site
DESTDIR = 
PREFIX = /usr
PERLPREFIX = $(PREFIX)
SITEPREFIX = $(PREFIX)/local
VENDORPREFIX = $(PREFIX)
INSTALLPRIVLIB = $(PERLPREFIX)/share/perl/5.18
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = $(SITEPREFIX)/share/perl/5.18.2
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = $(VENDORPREFIX)/share/perl5
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = $(PERLPREFIX)/lib/perl/5.18
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = $(SITEPREFIX)/lib/perl/5.18.2
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = $(VENDORPREFIX)/lib/perl5
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = $(PERLPREFIX)/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = $(SITEPREFIX)/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = $(VENDORPREFIX)/bin
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = $(PERLPREFIX)/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = $(SITEPREFIX)/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = $(VENDORPREFIX)/bin
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = $(PERLPREFIX)/share/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = $(SITEPREFIX)/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = $(VENDORPREFIX)/share/man/man1
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = $(PERLPREFIX)/share/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = $(SITEPREFIX)/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = $(VENDORPREFIX)/share/man/man3
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB =
PERL_ARCHLIB = /usr/lib/perl/5.18
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /usr/lib/perl/5.18/CORE
PERL = /usr/bin/perl "-Iinc"
FULLPERL = /usr/bin/perl "-Iinc"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /usr/share/perl/5.18/ExtUtils/MakeMaker.pm
MM_VERSION  = 6.66
MM_REVISION = 66600

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = Net/Amazon/IAM
BASEEXT = IAM
PARENT_NAME = Net::Amazon
DLBASE = $(BASEEXT)
VERSION_FROM = lib/Net/Amazon/IAM.pm
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = 
MAN3PODS = lib/Net/Amazon/IAM.pm \
	lib/Net/Amazon/IAM/AccessKey.pm \
	lib/Net/Amazon/IAM/AccessKeyMetadata.pm \
	lib/Net/Amazon/IAM/AccessKeysList.pm \
	lib/Net/Amazon/IAM/Error.pm \
	lib/Net/Amazon/IAM/Errors.pm \
	lib/Net/Amazon/IAM/GetGroupResult.pm \
	lib/Net/Amazon/IAM/Group.pm \
	lib/Net/Amazon/IAM/GroupPolicy.pm \
	lib/Net/Amazon/IAM/Groups.pm \
	lib/Net/Amazon/IAM/InstanceProfile.pm \
	lib/Net/Amazon/IAM/InstanceProfiles.pm \
	lib/Net/Amazon/IAM/LoginProfile.pm \
	lib/Net/Amazon/IAM/MFADevice.pm \
	lib/Net/Amazon/IAM/MFADevices.pm \
	lib/Net/Amazon/IAM/Policies.pm \
	lib/Net/Amazon/IAM/Policy.pm \
	lib/Net/Amazon/IAM/PolicyVersion.pm \
	lib/Net/Amazon/IAM/PolicyVersions.pm \
	lib/Net/Amazon/IAM/Role.pm \
	lib/Net/Amazon/IAM/Roles.pm \
	lib/Net/Amazon/IAM/User.pm \
	lib/Net/Amazon/IAM/UserPolicy.pm \
	lib/Net/Amazon/IAM/Users.pm \
	lib/Net/Amazon/IAM/VirtualMFADevice.pm \
	lib/Net/Amazon/IAM/VirtualMFADevices.pm

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)$(DFSEP)Config.pm $(PERL_INC)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)/Net/Amazon
INST_ARCHLIBDIR  = $(INST_ARCHLIB)/Net/Amazon

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/Net/Amazon/IAM.pm \
	lib/Net/Amazon/IAM/AccessKey.pm \
	lib/Net/Amazon/IAM/AccessKeyMetadata.pm \
	lib/Net/Amazon/IAM/AccessKeysList.pm \
	lib/Net/Amazon/IAM/Error.pm \
	lib/Net/Amazon/IAM/Errors.pm \
	lib/Net/Amazon/IAM/GetGroupResult.pm \
	lib/Net/Amazon/IAM/Group.pm \
	lib/Net/Amazon/IAM/GroupPolicy.pm \
	lib/Net/Amazon/IAM/Groups.pm \
	lib/Net/Amazon/IAM/InstanceProfile.pm \
	lib/Net/Amazon/IAM/InstanceProfiles.pm \
	lib/Net/Amazon/IAM/LoginProfile.pm \
	lib/Net/Amazon/IAM/MFADevice.pm \
	lib/Net/Amazon/IAM/MFADevices.pm \
	lib/Net/Amazon/IAM/Policies.pm \
	lib/Net/Amazon/IAM/Policy.pm \
	lib/Net/Amazon/IAM/PolicyVersion.pm \
	lib/Net/Amazon/IAM/PolicyVersions.pm \
	lib/Net/Amazon/IAM/Role.pm \
	lib/Net/Amazon/IAM/Roles.pm \
	lib/Net/Amazon/IAM/User.pm \
	lib/Net/Amazon/IAM/UserPolicy.pm \
	lib/Net/Amazon/IAM/Users.pm \
	lib/Net/Amazon/IAM/VirtualMFADevice.pm \
	lib/Net/Amazon/IAM/VirtualMFADevices.pm

PM_TO_BLIB = lib/Net/Amazon/IAM/GroupPolicy.pm \
	blib/lib/Net/Amazon/IAM/GroupPolicy.pm \
	lib/Net/Amazon/IAM/Group.pm \
	blib/lib/Net/Amazon/IAM/Group.pm \
	lib/Net/Amazon/IAM/Errors.pm \
	blib/lib/Net/Amazon/IAM/Errors.pm \
	lib/Net/Amazon/IAM/InstanceProfiles.pm \
	blib/lib/Net/Amazon/IAM/InstanceProfiles.pm \
	lib/Net/Amazon/IAM/MFADevice.pm \
	blib/lib/Net/Amazon/IAM/MFADevice.pm \
	lib/Net/Amazon/IAM/Groups.pm \
	blib/lib/Net/Amazon/IAM/Groups.pm \
	lib/Net/Amazon/IAM/Policies.pm \
	blib/lib/Net/Amazon/IAM/Policies.pm \
	lib/Net/Amazon/IAM/PolicyVersion.pm \
	blib/lib/Net/Amazon/IAM/PolicyVersion.pm \
	lib/Net/Amazon/IAM/Role.pm \
	blib/lib/Net/Amazon/IAM/Role.pm \
	lib/Net/Amazon/IAM/AccessKeyMetadata.pm \
	blib/lib/Net/Amazon/IAM/AccessKeyMetadata.pm \
	lib/Net/Amazon/IAM/AccessKeysList.pm \
	blib/lib/Net/Amazon/IAM/AccessKeysList.pm \
	lib/Net/Amazon/IAM/LoginProfile.pm \
	blib/lib/Net/Amazon/IAM/LoginProfile.pm \
	lib/Net/Amazon/IAM/PolicyVersions.pm \
	blib/lib/Net/Amazon/IAM/PolicyVersions.pm \
	lib/Net/Amazon/IAM/InstanceProfile.pm \
	blib/lib/Net/Amazon/IAM/InstanceProfile.pm \
	lib/Net/Amazon/IAM/Users.pm \
	blib/lib/Net/Amazon/IAM/Users.pm \
	lib/Net/Amazon/IAM.pm \
	blib/lib/Net/Amazon/IAM.pm \
	lib/Net/Amazon/IAM/VirtualMFADevice.pm \
	blib/lib/Net/Amazon/IAM/VirtualMFADevice.pm \
	lib/Net/Amazon/IAM/User.pm \
	blib/lib/Net/Amazon/IAM/User.pm \
	lib/Net/Amazon/IAM/UserPolicy.pm \
	blib/lib/Net/Amazon/IAM/UserPolicy.pm \
	lib/Net/Amazon/IAM/Policy.pm \
	blib/lib/Net/Amazon/IAM/Policy.pm \
	lib/Net/Amazon/IAM/GetGroupResult.pm \
	blib/lib/Net/Amazon/IAM/GetGroupResult.pm \
	lib/Net/Amazon/IAM/MFADevices.pm \
	blib/lib/Net/Amazon/IAM/MFADevices.pm \
	lib/Net/Amazon/IAM/AccessKey.pm \
	blib/lib/Net/Amazon/IAM/AccessKey.pm \
	lib/Net/Amazon/IAM/VirtualMFADevices.pm \
	blib/lib/Net/Amazon/IAM/VirtualMFADevices.pm \
	lib/Net/Amazon/IAM/Roles.pm \
	blib/lib/Net/Amazon/IAM/Roles.pm \
	lib/Net/Amazon/IAM/Error.pm \
	blib/lib/Net/Amazon/IAM/Error.pm


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 6.66
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:


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


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(PERL) -I. "-MModule::Install::Admin" -e "dist_preop(q($(DISTVNAME)))"
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = Net-Amazon-IAM
DISTVNAME = Net-Amazon-IAM-0.05


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	LD="$(LD)"\
	PREFIX="$(PREFIX)"


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)


pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

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

linkext :: $(LINKTYPE)
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) $(INST_DYNAMIC) $(INST_BOOT)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all  \
	lib/Net/Amazon/IAM/MFADevice.pm \
	lib/Net/Amazon/IAM/Groups.pm \
	lib/Net/Amazon/IAM/Policies.pm \
	lib/Net/Amazon/IAM/InstanceProfiles.pm \
	lib/Net/Amazon/IAM/Group.pm \
	lib/Net/Amazon/IAM/GroupPolicy.pm \
	lib/Net/Amazon/IAM/Errors.pm \
	lib/Net/Amazon/IAM/InstanceProfile.pm \
	lib/Net/Amazon/IAM/PolicyVersions.pm \
	lib/Net/Amazon/IAM/LoginProfile.pm \
	lib/Net/Amazon/IAM/AccessKeysList.pm \
	lib/Net/Amazon/IAM/PolicyVersion.pm \
	lib/Net/Amazon/IAM/Role.pm \
	lib/Net/Amazon/IAM/AccessKeyMetadata.pm \
	lib/Net/Amazon/IAM/Policy.pm \
	lib/Net/Amazon/IAM/VirtualMFADevice.pm \
	lib/Net/Amazon/IAM/UserPolicy.pm \
	lib/Net/Amazon/IAM/User.pm \
	lib/Net/Amazon/IAM.pm \
	lib/Net/Amazon/IAM/Users.pm \
	lib/Net/Amazon/IAM/Roles.pm \
	lib/Net/Amazon/IAM/Error.pm \
	lib/Net/Amazon/IAM/MFADevices.pm \
	lib/Net/Amazon/IAM/VirtualMFADevices.pm \
	lib/Net/Amazon/IAM/AccessKey.pm \
	lib/Net/Amazon/IAM/GetGroupResult.pm
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) \
	  lib/Net/Amazon/IAM/MFADevice.pm $(INST_MAN3DIR)/Net::Amazon::IAM::MFADevice.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/Groups.pm $(INST_MAN3DIR)/Net::Amazon::IAM::Groups.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/Policies.pm $(INST_MAN3DIR)/Net::Amazon::IAM::Policies.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/InstanceProfiles.pm $(INST_MAN3DIR)/Net::Amazon::IAM::InstanceProfiles.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/Group.pm $(INST_MAN3DIR)/Net::Amazon::IAM::Group.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/GroupPolicy.pm $(INST_MAN3DIR)/Net::Amazon::IAM::GroupPolicy.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/Errors.pm $(INST_MAN3DIR)/Net::Amazon::IAM::Errors.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/InstanceProfile.pm $(INST_MAN3DIR)/Net::Amazon::IAM::InstanceProfile.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/PolicyVersions.pm $(INST_MAN3DIR)/Net::Amazon::IAM::PolicyVersions.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/LoginProfile.pm $(INST_MAN3DIR)/Net::Amazon::IAM::LoginProfile.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/AccessKeysList.pm $(INST_MAN3DIR)/Net::Amazon::IAM::AccessKeysList.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/PolicyVersion.pm $(INST_MAN3DIR)/Net::Amazon::IAM::PolicyVersion.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/Role.pm $(INST_MAN3DIR)/Net::Amazon::IAM::Role.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/AccessKeyMetadata.pm $(INST_MAN3DIR)/Net::Amazon::IAM::AccessKeyMetadata.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/Policy.pm $(INST_MAN3DIR)/Net::Amazon::IAM::Policy.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/VirtualMFADevice.pm $(INST_MAN3DIR)/Net::Amazon::IAM::VirtualMFADevice.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/UserPolicy.pm $(INST_MAN3DIR)/Net::Amazon::IAM::UserPolicy.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/User.pm $(INST_MAN3DIR)/Net::Amazon::IAM::User.$(MAN3EXT) \
	  lib/Net/Amazon/IAM.pm $(INST_MAN3DIR)/Net::Amazon::IAM.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/Users.pm $(INST_MAN3DIR)/Net::Amazon::IAM::Users.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/Roles.pm $(INST_MAN3DIR)/Net::Amazon::IAM::Roles.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/Error.pm $(INST_MAN3DIR)/Net::Amazon::IAM::Error.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/MFADevices.pm $(INST_MAN3DIR)/Net::Amazon::IAM::MFADevices.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/VirtualMFADevices.pm $(INST_MAN3DIR)/Net::Amazon::IAM::VirtualMFADevices.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/AccessKey.pm $(INST_MAN3DIR)/Net::Amazon::IAM::AccessKey.$(MAN3EXT) \
	  lib/Net/Amazon/IAM/GetGroupResult.pm $(INST_MAN3DIR)/Net::Amazon::IAM::GetGroupResult.$(MAN3EXT) 




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
	  *$(LIB_EXT) mon.out \
	  core.*perl.*.? perlmain.c \
	  core.[0-9] $(BASEEXT).exp \
	  so_locations $(INST_ARCHAUTODIR)/extralibs.ld \
	  $(BASEEXT).bso pm_to_blib \
	  *$(OBJ_EXT) core.[0-9][0-9][0-9][0-9] \
	  perl.exe $(INST_ARCHAUTODIR)/extralibs.all \
	  perl tmon.out \
	  blibdirs.ts $(BASEEXT).def \
	  lib$(BASEEXT).def core.[0-9][0-9][0-9][0-9][0-9] \
	  core.[0-9][0-9] pm_to_blib.ts \
	  $(BASEEXT).x *perl.core \
	  MYMETA.yml core.[0-9][0-9][0-9] \
	  $(MAKE_APERL_FILE) perl$(EXE_EXT) \
	  $(BOOTSTRAP) core \
	  MYMETA.json 
	- $(RM_RF) \
	  blib 
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
realclean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge ::  clean realclean_subdirs
	- $(RM_F) \
	  $(FIRST_MAKEFILE) $(MAKEFILE_OLD) 
	- $(RM_RF) \
	  MYMETA.yml $(DISTVNAME) 


# --- MakeMaker metafile section:
metafile :
	$(NOECHO) $(NOOP)


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

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir  
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:

ci :
	$(PERLRUN) "-MExtUtils::Manifest=maniread" \
	  -e "@all = keys %{ maniread() };" \
	  -e "print(qq{Executing $(CI) @all\n}); system(qq{$(CI) @all});" \
	  -e "print(qq{Executing $(RCS_LABEL) ...\n}); system(qq{$(RCS_LABEL) @all});"


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
	  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
	  -e '    or print "Could not add META.yml to MANIFEST: $$$${'\''@'\''}\n"' --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
	  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
	  -e '    or print "Could not add META.json to MANIFEST: $$$${'\''@'\''}\n"' --



# --- MakeMaker distsignature section:
distsignature : create_distdir
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) } ' \
	  -e '    or print "Could not add SIGNATURE to MANIFEST: $$$${'\''@'\''}\n"' --
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
	$(NOECHO) umask 022; $(MOD_INSTALL) \
		$(INST_LIB) $(DESTINSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLARCHLIB) \
		$(INST_BIN) $(DESTINSTALLBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)/auto/$(FULLEXT)


pure_site_install :: all
	$(NOECHO) umask 02; $(MOD_INSTALL) \
		read $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLSITELIB) \
		$(INST_ARCHLIB) $(DESTINSTALLSITEARCH) \
		$(INST_BIN) $(DESTINSTALLSITEBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSITESCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLSITEMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLSITEMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)/auto/$(FULLEXT)

pure_vendor_install :: all
	$(NOECHO) umask 022; $(MOD_INSTALL) \
		$(INST_LIB) $(DESTINSTALLVENDORLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLVENDORARCH) \
		$(INST_BIN) $(DESTINSTALLVENDORBIN) \
		$(INST_SCRIPT) $(DESTINSTALLVENDORSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLVENDORMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLVENDORMAN3DIR)

doc_perl_install :: all

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLSITEARCH)/perllocal.pod
	-$(NOECHO) umask 02; $(MKPATH) $(DESTINSTALLSITEARCH)
	-$(NOECHO) umask 02; $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLSITEARCH)/perllocal.pod

doc_vendor_install :: all


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist

uninstall_from_vendordirs ::



# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:
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
FULLPERL      = /usr/bin/perl

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/00-load.t t/boilerplate.t t/manifest.t t/pod-coverage.t t/pod.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)

test :: $(TEST_TYPE) subdirs-test

subdirs-test ::
	$(NOECHO) $(NOOP)


test_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE), 'inc', '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-Iinc" "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

test_ : test_dynamic

test_static :: test_dynamic
testdb_static :: testdb_dynamic


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="$(DISTNAME)" VERSION="$(VERSION)">' > $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT>Perl interface to the Amazon Identity and Access Management.</ABSTRACT>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>Igor Tsigankov &lt;tsiganenok@gmail.com&gt;</AUTHOR>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="AWS::Signature4" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Carp::" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Data::Dumper" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="HTTP::Request::Common" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="JSON::" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="LWP::Protocol::https" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="LWP::UserAgent" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Moose::" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="POSIX::" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Params::Validate" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="URI::" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="URI::Encode" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="XML::Simple" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="x86_64-linux-gnu-thread-multi-5.18" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> $(DISTNAME).ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/Net/Amazon/IAM/GroupPolicy.pm blib/lib/Net/Amazon/IAM/GroupPolicy.pm \
	  lib/Net/Amazon/IAM/Group.pm blib/lib/Net/Amazon/IAM/Group.pm \
	  lib/Net/Amazon/IAM/Errors.pm blib/lib/Net/Amazon/IAM/Errors.pm \
	  lib/Net/Amazon/IAM/InstanceProfiles.pm blib/lib/Net/Amazon/IAM/InstanceProfiles.pm \
	  lib/Net/Amazon/IAM/MFADevice.pm blib/lib/Net/Amazon/IAM/MFADevice.pm \
	  lib/Net/Amazon/IAM/Groups.pm blib/lib/Net/Amazon/IAM/Groups.pm \
	  lib/Net/Amazon/IAM/Policies.pm blib/lib/Net/Amazon/IAM/Policies.pm \
	  lib/Net/Amazon/IAM/PolicyVersion.pm blib/lib/Net/Amazon/IAM/PolicyVersion.pm \
	  lib/Net/Amazon/IAM/Role.pm blib/lib/Net/Amazon/IAM/Role.pm \
	  lib/Net/Amazon/IAM/AccessKeyMetadata.pm blib/lib/Net/Amazon/IAM/AccessKeyMetadata.pm \
	  lib/Net/Amazon/IAM/AccessKeysList.pm blib/lib/Net/Amazon/IAM/AccessKeysList.pm \
	  lib/Net/Amazon/IAM/LoginProfile.pm blib/lib/Net/Amazon/IAM/LoginProfile.pm \
	  lib/Net/Amazon/IAM/PolicyVersions.pm blib/lib/Net/Amazon/IAM/PolicyVersions.pm \
	  lib/Net/Amazon/IAM/InstanceProfile.pm blib/lib/Net/Amazon/IAM/InstanceProfile.pm \
	  lib/Net/Amazon/IAM/Users.pm blib/lib/Net/Amazon/IAM/Users.pm \
	  lib/Net/Amazon/IAM.pm blib/lib/Net/Amazon/IAM.pm \
	  lib/Net/Amazon/IAM/VirtualMFADevice.pm blib/lib/Net/Amazon/IAM/VirtualMFADevice.pm \
	  lib/Net/Amazon/IAM/User.pm blib/lib/Net/Amazon/IAM/User.pm \
	  lib/Net/Amazon/IAM/UserPolicy.pm blib/lib/Net/Amazon/IAM/UserPolicy.pm \
	  lib/Net/Amazon/IAM/Policy.pm blib/lib/Net/Amazon/IAM/Policy.pm \
	  lib/Net/Amazon/IAM/GetGroupResult.pm blib/lib/Net/Amazon/IAM/GetGroupResult.pm \
	  lib/Net/Amazon/IAM/MFADevices.pm blib/lib/Net/Amazon/IAM/MFADevices.pm \
	  lib/Net/Amazon/IAM/AccessKey.pm blib/lib/Net/Amazon/IAM/AccessKey.pm \
	  lib/Net/Amazon/IAM/VirtualMFADevices.pm blib/lib/Net/Amazon/IAM/VirtualMFADevices.pm \
	  lib/Net/Amazon/IAM/Roles.pm blib/lib/Net/Amazon/IAM/Roles.pm \
	  lib/Net/Amazon/IAM/Error.pm blib/lib/Net/Amazon/IAM/Error.pm 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:


# End.
# Postamble by Module::Install 1.14
# --- Module::Install::Admin::Makefile section:

realclean purge ::
	$(RM_F) $(DISTVNAME).tar$(SUFFIX)
	$(RM_F) MANIFEST.bak _build
	$(PERL) "-Ilib" "-MModule::Install::Admin" -e "remove_meta()"
	$(RM_RF) inc

reset :: purge

upload :: test dist
	cpan-upload -verbose $(DISTVNAME).tar$(SUFFIX)

grok ::
	perldoc Module::Install

distsign ::
	cpansign -s

# --- Module::Install::AutoInstall section:

config :: installdeps
	$(NOECHO) $(NOOP)

checkdeps ::
	$(PERL) Makefile.PL --checkdeps

installdeps ::
	$(NOECHO) $(NOOP)

installdeps_notest ::
	$(NOECHO) $(NOOP)

upgradedeps ::
	$(PERL) Makefile.PL --config= --upgradedeps=URI,0,Carp,0,JSON,0,URI::Encode,0,XML::Simple,0,POSIX,0,LWP::UserAgent,0,LWP::Protocol::https,0,Data::Dumper,0,Params::Validate,0,HTTP::Request::Common,0,AWS::Signature4,0,Moose,0

upgradedeps_notest ::
	$(PERL) Makefile.PL --config=notest,1 --upgradedeps=URI,0,Carp,0,JSON,0,URI::Encode,0,XML::Simple,0,POSIX,0,LWP::UserAgent,0,LWP::Protocol::https,0,Data::Dumper,0,Params::Validate,0,HTTP::Request::Common,0,AWS::Signature4,0,Moose,0

listdeps ::
	@$(PERL) -le "print for @ARGV" 

listalldeps ::
	@$(PERL) -le "print for @ARGV" URI Carp JSON URI::Encode XML::Simple POSIX LWP::UserAgent LWP::Protocol::https Data::Dumper Params::Validate HTTP::Request::Common AWS::Signature4 Moose

