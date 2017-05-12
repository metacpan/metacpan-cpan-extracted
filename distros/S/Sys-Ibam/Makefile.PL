use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $CC;

use Config;

if ($ENV{CC}) {
	$CC = $ENV{CC};
} elsif ($Config{gccversion} and $Config{cc}  =~ m#\bgcc\b[^/]*$#) {
	($CC = $Config{cc}) =~ s[\bgcc\b([^/]*)$(?:)][g\+\+$1];
} elsif ($Config{osname} =~ /^MSWin/) {
	$CC = 'cl -TP';
} elsif ($Config{osname} eq 'linux') {
	$CC = 'g++';
} elsif ($Config{osname} eq 'cygwin') {
	$CC = 'g++';
} elsif ($Config{osname} eq 'solaris' or $Config{osname} eq 'SunOS') {
	if ($Config{cc} eq 'gcc') {
		$CC = 'g++';
	} else {
		$CC = 'CC';
	}
} else {
	$CC = 'g++';
}

WriteMakefile(
    NAME              => 'Sys::Ibam',
    VERSION_FROM      => 'lib/Sys/Ibam.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sys/Ibam.pm', # retrieve abstract from module
       AUTHOR         => 'Florian Ragwitz <florian@mookooh.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '-DIBAM_VERSION=\"0.3\"', # e.g., '-DHAVE_SOMETHING'
	CC                => $CC,
	CCFLAGS           => '-Wall',
	LD                => '$(CC)',
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
	XSOPT             => '-C++'
);
