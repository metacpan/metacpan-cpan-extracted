# $Id: Makefile.PL,v 1.9 2007/10/08 08:32:25 dk Exp $
use strict;
use Config;
use ExtUtils::Packlist;

my $lib1 = $Config{installsitebin};
my $lib2 = "$Config{installsitearch}/Prima/prigraph";
my $lib3 = $Config{installsitearch};

my @path = split $Config{path_sep}, lc $ENV{PATH};
my %path = map { $_ => 1 } @path;
unless ( $path{ lc $lib1}) {
	warn "** warning, $lib1 is not in PATH.\n";
	for ( @path) {
		next unless -d $_ and -w _;
		warn "** installing prigraph.dll in $_ instead\n";
		$lib1 = $_;
		last;
	}
}


my ( $version, $V1, $V2);
open F, 'win32.pm';
while (<F>) {
	next unless /VERSION\s*=\s*\'([\d\.]+)\'/;
	$version = $1;
	$version =~ /^(\d+)\.(\d+)$/;
	( $V1, $V2) = ( $1, $2);
}
close F;

die "Cannot determine version from win32.pm\n"
	unless defined $version;
my $name = "Prima-prigraph-win32";
my $dist = "$name-$version";

open F, "< MANIFEST" or die "Cannot open MANIFEST:$!\n";
my @F     = <F>;
my $dist_files_copy = join("\n\t", map { chomp; "\$(CP) $_ $dist"} @F);
my $dist_files_rm   = join("\n\t", map { chomp; "\$(RM) $dist\\$_" } @F);
close F;
my $packlist = ExtUtils::Packlist-> new();
$packlist->{"$lib1/$_"}++ for 'prigraph.dll';
$packlist->{"$lib2/$_"}++ for 'win32.pm';
$packlist->{"$lib3/$_"}++ for 'prigraph.lib', 'prigraph.def', 'libprigraph.a';
$packlist->write('.packlist');

my ( $CP, $RM, $Q);
if ( $^O eq 'cygwin') {
	$CP = 'cp';
	$RM = 'rm';
	$Q  = '/';
	s[\\][/]g for $lib1, $lib2, $lib3;
} else {
	$CP = 'cmd /c copy /b /y';
	$RM = 'cmd /c del';
	$Q  = '\\';
	s[/][\\]g for $lib1, $lib2, $lib3;
}

open F, "> Makefile" or die "Cannot open Makefile:$!\n";
print F <<MAKEFILE;
CP=$CP
RM=$RM
MKDIR=$^X -MExtUtils::Command -e mkpath
DIST=$dist

all:

mkpath:
	\$(MKDIR) $lib1
	\$(MKDIR) $lib2
	\$(MKDIR) $lib3

ppd:
	$^X -e "print qq{<SOFTPKG NAME=\\"$name\\" VERSION=\\"$V1,$V2,0,0\\">\\n}. qq{\\t<TITLE>Prima prigraph for win32</TITLE>\\n}. qq{\\t<ABSTRACT>Default image codec for Prima</ABSTRACT>\\n}. qq{\\t<AUTHOR>Dmitry Karasik</AUTHOR>\\n}. qq{\\t<IMPLEMENTATION>\\n}. qq{\\t\\t<OS NAME=\\"$^O\\" />\\n}. qq{\\t\\t<ARCHITECTURE NAME=\\"$Config{myarchname}\\" />\\n}. qq{\\t\\t<CODEBASE HREF=\\"http://www.prima.eu.org/download/gbm-bin-win32.tar.gz\\" />\\n}. qq{\\t</IMPLEMENTATION>\\n}. qq{</SOFTPKG>\\n}" > $name.ppd

install: mkpath
	\$(CP) prigraph.dll $lib1
	\$(CP) prigraph.lib $lib3
	\$(CP) prigraph.def $lib3
	\$(CP) libprigraph.a $lib3
	\$(CP) win32.pm $lib2
	\$(CP) .packlist $lib2

deinstall:
	\$(RM) $lib1${Q}prigraph.dll
	\$(RM) $lib3${Q}prigraph.lib
	\$(RM) $lib3${Q}libprigraph.a
	\$(RM) $lib2${Q}win32.pm
	\$(RM) $lib2${Q}.packlist
	rmdir $lib2
	rmdir $lib1

dist:
	\$(MKDIR) $dist
	$dist_files_copy
	zip -r $dist.zip $dist
	$dist_files_rm
	rmdir $dist

clean:

test:
MAKEFILE
close F;
