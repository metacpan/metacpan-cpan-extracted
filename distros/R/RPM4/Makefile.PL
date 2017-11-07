# $Id$

# use 5.008;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;
use Getopt::Long;
use strict;

# minimum required version of dependencies we need to build
our %build_reqs = (
	'rpm' => '4.9.0',
);
our %CONFIGURE_REQUIRES = (
	'ExtUtils::MakeMaker' => '6.64',
	'ExtUtils::Depends' => '0',
	'ExtUtils::PkgConfig' => '0',
	'Getopt::Long' => '0',
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends '$CONFIGURE_REQUIRES{'ExtUtils::Depends'}';"
           . "use ExtUtils::PkgConfig '$CONFIGURE_REQUIRES{'ExtUtils::PkgConfig'}';"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         NAME         => 'URPM',
         PREREQ_FATAL => 1,
         PREREQ_PM    => \%CONFIGURE_REQUIRES,
   );
   exit 1; # not reached
}

my %cfg;
unless (eval { %cfg = ExtUtils::PkgConfig->find("rpm >= $build_reqs{rpm}"); 1 })
{
	warn $@;
	exit 0;
}

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
    LICENSE      => 'gpl_2',
    META_MERGE => {
	'meta-spec' => { version => 2 },
        resources => {
            repository  => {
		type => 'git',
		url => 'git://git.mageia.org/software/rpm/perl-RPM4/',
		web =>  'http://gitweb.mageia.org/software/rpm/perl-RPM4/',
	    },
        },
	release_status => 'stable'
    },
    MIN_PERL_VERSION => '5.008001',
    CONFIGURE_REQUIRES => \%CONFIGURE_REQUIRES,
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
