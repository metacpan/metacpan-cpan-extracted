# $Id$

# use 5.008;
use ExtUtils::MakeMaker;
use Getopt::Long;

#- require at least rpm 4.9
my $rpm_version = `LC_ALL=C rpm --version` =~ /version ([0-9.]+)(?:-(?:beta|rc).*)?$/ ? version->new("v$1") : ();
$rpm_version ge 4.9.0
    or die <<BARF;
Unable to build RPM4 with too old (or undetected) rpm version $rpm_version
BARF

sub MY::postamble() {
    <<MAKECHANGELOG;
.PHONY: ChangeLog copyrpmconstant

copyrpmconstant:
	make -C src copyrpmconstant

ChangeLog:
	LC_ALL=C svn update && LC_ALL=C svn log --verbose > \$@

rpm: dist
	rpm --rmsource --define "_sourcedir `pwd`" -ba perl-Hdlist.spec
MAKECHANGELOG
}

WriteMakefile(
    NAME	 => 'RPM4',
    VERSION_FROM => 'lib/RPM4.pm',
    DIR          => [ 'src' ],
    'EXE_FILES'  => [ qw(bin/rpm_produced bin/rpmresign bin/hrpmreb) ],
    depend => { dist => 'copyrpmconstant' },
    PREREQ_PM => {
        Carp => 0,
        'Digest::SHA1' => 0,
        DynaLoader => 0,
        Exporter => 0,
        'File::Temp' => 0,
        'MDV::Packdrakeng' => 0,
    },
    dist => { COMPRESS => "xz", SUFFIX => ".xz" },
);
