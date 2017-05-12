use 5.008;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'libsane' => '1.0.19',
);

# minimum required version of dependancies we need to run
our %runtime_reqs = (
	'libsane' => '1.0.19',
);

# Can't assume ExtUtils::PkgConfig will return anything useful until
# the pkg-config files ship with sane.
my $lib = '-lsane';
my $inc = '-I. ';
if (eval {
  %pkgcfg = ExtUtils::PkgConfig->find ('sane-backends >= '. $build_reqs{libsane})
}) {
 $lib = $pkgcfg{libs};
 $inc .= $pkgcfg{cflags};
 $runtime_reqs{libsane} = $pkgcfg{modversion};
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sane',
    VERSION_FROM      => 'lib/Sane.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sane.pm', # retrieve abstract from module
       AUTHOR         => 'Jeffrey Ratcliffe') : ()),
    LIBS              => [$lib], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => $inc, # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
