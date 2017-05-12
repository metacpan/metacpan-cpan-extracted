use warnings FATAL => 'all';
use strict;

use 5.008007;
use Config;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;
use ExtUtils::Depends;
use File::Slurp;

my %pkgcfg = ExtUtils::PkgConfig->find("mozilla-gtkmozembed >= 1.7"
		, "firefox-gtkmozembed >= 1.5");

my $ver = $pkgcfg{modversion};
$ver =~ s/\.//g;
mkdir "build";
write_file("build/version.h", "#define MCS_MOZEMBED_VERSION $ver\n");

my $dep = ExtUtils::Depends->new('Mozilla::ConsoleService', 'Gtk2::MozEmbed');
$dep->set_inc($pkgcfg{cflags});
$dep->set_libs($pkgcfg{libs});

WriteMakefile(
    NAME              => 'Mozilla::ConsoleService',
    VERSION_FROM      => 'lib/Mozilla/ConsoleService.pm', # finds $VERSION
    PREREQ_PM         => { 'Mozilla::Mechanize' => 0.05 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mozilla/ConsoleService.pm', # retrieve abstract from module
       AUTHOR         => 'Boris Sukholitko <boriss@gmail.com>') : ()),
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    CC            => 'g++',
    LD            => "$Config{ld}",
    $dep->get_makefile_vars
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
