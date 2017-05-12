# $Id$
# -*- perl -*-

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME => "Test-AutoBuild",
              VERSION_FROM => 'lib/Test/AutoBuild.pm',
              AUTHOR => "Daniel Berrange (dan[at]berrange[dot]com)",
              EXE_FILES => ['bin/auto-build', 'bin/auto-build-make-root', 'bin/auto-build-clean-root'],
              NO_META => 1,
              PREREQ_PM => {
                  'BSD::Resource' => "1.10",
                  'Carp' => '0',
                  'Class::MethodMaker' => '0',
		  'Config' => '0',
		  'Cwd' => '0',
                  'Config::Record' => '1.1.0',
		  'Data::Dumper' => '0',
                  'Date::Manip' => '0',
                  'Digest::MD5' => '0',
                  'Fcntl' => '0',
                  'File::Copy' => '0',
                  'File::Find' => '0',
		  'File::Glob' => '0',
                  'File::Path' => '0',
		  'File::ReadBackwards' => '0',
		  'File::Spec' => '0',
		  'File::stat' => '0',
		  'IO::File' => '0',
                  'IO::Scalar' => '0',
		  'List::Util' => '0',
                  'Log::Log4perl' => "0",
                  'Net::SMTP' => "2.15",
                  'POSIX' => '0',
		  'Storable' => '0',
		  'Symbol' => '0',
                  'Sys::Hostname' => '0',
                  'Template' => '0',
		  'Test::More' => '0',
		  'XML::Simple' => '0',
              },
              dist =>
              {
                  COMPRESS => 'gzip --force --best',
              },
              clean =>
              {
                  FILES => '*.bak *~',
              },
              depend => {
                  Makefile => '$(VERSION_FROM)',
                  #'perl-Test-AutoBuild.spec' => '$(VERSION_FROM)',
                  dist => 'perl-Test-AutoBuild.spec META.yml',
              },
              realclean => {
                  FILES => 'Test-AutoBuild-*.tar.gz perl-Test-AutoBuild.spec',
              },
              );

package MY;

sub postamble {
    '
WITH_SELINUX    = 0

# NB do not use prefix here
SELINUXDEV   = /usr/share/selinux/devel

pure_all ::
	if [ -d "$(SELINUXDEV)" -a "$(WITH_SELINUX)" = "1" ] ; then make -C conf/selinux ; fi

clean ::
	if [ -d "$(SELINUXDEV)" -a "$(WITH_SELINUX)" = "1" ] ; then make -C conf/selinux clean ; fi

HTMLDIR = blib/html

HTMLURLPREFIX = /
HTMLPODS = $(MAN3PODS:lib/%.pm=$(HTMLDIR)/%.html)

MAN5EXT = 5
INST_MAN5DIR = blib/man5
INST_SYSCONF = blib/sysconf
INST_SELINUX = blib/selinux

INSTALLSYSCONF = $(PERLPREFIX)/etc
DESTINSTALLSYSCONF = $(DESTDIR)/$(INSTALLSYSCONF)
INSTALLSELINUX = $(PERLPREFIX)/share/selinux
DESTINSTALLSELINUX = $(DESTDIR)/$(INSTALLSELINUX)

$(INST_MAN5DIR)/.exists :: $(INST_MAN3DIR)/.exists
	$(NOECHO) $(MKPATH) $(INST_MAN5DIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) $(INST_MAN3DIR)/.exists $(INST_MAN5DIR)/.exists
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_MAN5DIR)

$(INST_SYSCONF)/.exists :: $(INST_MAN3DIR)/.exists
	$(NOECHO) $(MKPATH) $(INST_SYSCONF)
	$(NOECHO) $(MKPATH) $(INST_SYSCONF)/templates
	$(NOECHO) $(MKPATH) $(INST_SYSCONF)/cron
	$(NOECHO) $(MKPATH) $(INST_SYSCONF)/httpd
	$(NOECHO) $(MKPATH) $(INST_SYSCONF)/engine
	$(NOECHO) $(EQUALIZE_TIMESTAMP) $(INST_MAN3DIR)/.exists $(INST_SYSCONF)/.exists
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SYSCONF)

$(INST_SELINUX)/.exists :: $(INST_MAN3DIR)/.exists
	$(NOECHO) $(MKPATH) $(INST_SELINUX)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) $(INST_MAN3DIR)/.exists $(INST_SELINUX)/.exists
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SELINUX)

all:: manify5pods prepconf prepscripts prepselinux

manify5pods: $(INST_MAN5DIR)/.exists conf/auto-build.conf.pod
	$(NOECHO) $(POD2MAN_EXE) --section=5 --perm_rw=$(PERM_RW)\
          conf/auto-build.conf.pod $(INST_MAN5DIR)/auto-build.conf.$(MAN5EXT)

prepconf: $(INST_SYSCONF)/.exists
	$(NOECHO) for i in conf/*.conf conf/engine/*.conf conf/cron/*.conf conf/httpd/*.conf; do \
		conf=`echo $$i | sed -e \'s/conf\///\'`; \
                $(RM_F) $(INST_SYSCONF)/$$conf; \
                $(CP) $$i $(INST_SYSCONF)/$$conf; \
                $(FIXIN) $(INST_SYSCONF)/$$conf; \
                $(CHMOD) $(PERM_RW) $(INST_SYSCONF)/$$conf; \
	done
	$(NOECHO) for i in templates/*.txt templates/*.html templates/*.tt templates/*.css templates/*.rss templates/*.png ; do \
                $(RM_F) $(INST_SYSCONF)/$$i; \
                $(CP) $$i $(INST_SYSCONF)/$$i; \
                $(FIXIN) $(INST_SYSCONF)/$$i; \
                $(CHMOD) $(PERM_RW) $(INST_SYSCONF)/$$i; \
        done

prepscripts: $(INST_SCRIPT)/.exists
	if [ -d "$(SELINUXDEV)" -a "$(WITH_SELINUX)" = "1" ]; then \
		$(RM_F) $(INST_SCRIPT)/auto-build-secure; \
		$(CP) bin/auto-build $(INST_SCRIPT)/auto-build-secure; \
		$(FIXIN) $(INST_SCRIPT)/auto-build-secure; \
		$(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/auto-build-secure; \
	fi

prepselinux: $(INST_SELINUX)/.exists
	if [ -d "$(SELINUXDEV)" -a "$(WITH_SELINUX)" = "1" ]; then \
		$(RM_F) $(INST_SELINUX)/auto-build.pp; \
		$(CP) conf/selinux/auto-build.pp $(INST_SELINUX)/auto-build.pp; \
		$(FIXIN) $(INST_SELINUX)/auto-build.pp; \
		$(CHMOD) $(PERM_RW) $(INST_SELINUX)/auto-build.pp; \
	fi

INSTALLMAN5 = $(PERLPREFIX)/share/man/man5
DESTINSTALLMAN5 = $(DESTDIR)$(INSTALLMAN5)
INSTALLSITEMAN5 = $(SITEPREFIX)/share/man/man5
DESTINSTALLSITEMAN5 = $(DESTDIR)$(INSTALLSITEMAN5)
INSTALLVENDORMAN5 = $(VENDORPREFIX)/share/man/man5
DESTINSTALLVENDORMAN5 = $(DESTDIR)$(INSTALLVENDORMAN5)

pure_perl_install ::
	$(MOD_INSTALL) $(INST_MAN5DIR) $(DESTINSTALLMAN5)
	$(MOD_INSTALL) $(INST_SYSCONF) $(DESTINSTALLSYSCONF)/auto-build.d
	$(MOD_INSTALL) $(INST_SELINUX) $(DESTINSTALLSELINUX)/packages

pure_site_install ::
	$(MOD_INSTALL) $(INST_MAN5DIR) $(DESTINSTALLSITEMAN5)
	$(MOD_INSTALL) $(INST_SYSCONF) $(DESTINSTALLSYSCONF)/auto-build.d
	$(MOD_INSTALL) $(INST_SELINUX) $(DESTINSTALLSELINUX)/packages

pure_vendor_install ::
	$(MOD_INSTALL) $(INST_MAN5DIR) $(DESTINSTALLVENDORMAN5)
	$(MOD_INSTALL) $(INST_SYSCONF) $(DESTINSTALLSYSCONF)/auto-build.d
	$(MOD_INSTALL) $(INST_SELINUX) $(DESTINSTALLSELINUX)/packages


htmlifypods: $(HTMLDIR) $(HTMLPODS)

$(HTMLDIR):
	mkdir $@

$(HTMLDIR)/%.html: lib/%.pm
	mkdir -p `dirname $@`
	pod2html --htmlroot=$(HTMLURLPREFIX) --infile=$< --outfile=$@ --podpath=$(HTMLDIR)

';
}

sub test {
    my $self = shift;
    my $mm_test = $self->SUPER::test(@_);

    return '
test :: META.yml
' . $mm_test;
  }

__END__
