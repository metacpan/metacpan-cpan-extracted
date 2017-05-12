
use strict;
use ExtUtils::MakeMaker;
BEGIN {
    require 'src/PersistentMake.pl';
    import PersistentMake qw(%write_makefile_common);
}

print <<END;

Optional mod_persistentperl support.

Mod_persistentperl increases performance under Apache by avoiding the fork/exec
overhead associated with each request under normal PersistentPerl.  However, it
requires a working copy of "apxs" in your path, Apache with mod_so
support, and additional Apache configuration.

END
print "Compile mod_persistentperl (default no)? ";

my @dirs = qw(src perperl_backend perperl);
my $macro = $write_makefile_common{macro};
my $apache_module = 0;
if (<STDIN> =~ /y/i) {
    die "ERROR: Command 'apxs -q CC' failed.\n"
	unless $macro->{APACHE_APXS_WORKS};
    print "Compiling for Apache version $macro->{APACHE_VERSION}\n";
    push(@dirs, $macro->{MOD_PERSISTENTPERL_DIR});
    $apache_module = 1;
}

WriteMakefile(
    NAME		=> 'PersistentPerl',
    VERSION_FROM	=> 'src/PersistentPerl.src',
    EXE_FILES		=> [qw(perperl/perperl perperl_backend/perperl_backend)],
    CONFIGURE		=> sub { return {DIR=>\@dirs} },
    PM			=> {'src/PersistentPerl.pm'=>'$(INST_LIBDIR)/PersistentPerl.pm'},
    MAN1PODS		=> {},
    MAN3PODS		=> {},
    dist		=> {DIST_DEFAULT => 'mydist'},
    realclean		=> {FILES => 'README README.html lib'},
    %write_makefile_common
);

package MY;

use ExtUtils::Embed;

sub postamble {
    my $extra = PersistentMake->optdefs_cmds('src');
    my $test_install_extra;
    if ($apache_module) {
	my $mod_dir = $macro->{MOD_PERSISTENTPERL_DIR};
	$extra .=
	    "\ninstall ::\n\tcd $mod_dir && \$(MAKE) install\n";
	$test_install_extra =
	    "\t\@cd $mod_dir && \$(MAKE) test_install \$(PASTHRU)\n";
    }

'
test_install:
	@cd perperl && $(MAKE) test_install $(PASTHRU)
' .
$test_install_extra .
'

mydist: README README.html lib/PersistentPerl.pm readable tardist

readable:
	chown -R $(USER) .
	chmod -R u+w,go-w,go+r .

README: src/PersistentPerl.pm
	cd src && $(PERL) -e "use Pod::Text; pod2text(-80)" <PersistentPerl.pm >../README

README.html: src/PersistentPerl.pm
	cd src && pod2html PersistentPerl.pm >../README.html && $(RM_F) pod2h*

lib/PersistentPerl.pm: src/PersistentPerl.pm
	$(MKPATH) lib/CGI
	$(CP) src/PersistentPerl.pm lib/PersistentPerl.pm

MAKE_INDEX = $(PERL) -w ./util/build_index $(VERSION)

rpm: package

rpms: rpm

solpkg: package

sunpkg: solpkg

bsdpkg: package

package: all README README.html
	./util/build_package $(VERSION) $(INSTALLBIN) $(INSTALLSITELIB) $(APACHE_VERSION) $(APACHE_LIBEXECDIR) $(APACHE_SYSCONFDIR) $(MOD_PERSISTENTPERL_DIR)
	$(MAKE_INDEX)
	@echo "*** Package files can be found in the binaries directory"

package_index:
	$(MAKE_INDEX)

' . $extra;
}
