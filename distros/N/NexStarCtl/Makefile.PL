use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $required;
if ($^O eq "MSWin32") {
	$required = { 'Win32::SerialPort' => 0.1 };
} else {
	$required = { 'Device::SerialPort' => 0.1 };
}

WriteMakefile(
    NAME              => 'NexStarCtl',
    VERSION_FROM      => 'lib/NexStarCtl.pm', # finds $VERSION
    PM                => { 'nexstarctl/nexstarctl.pl' => '$(INST_BIN)/nexstarctl',
                           'lib/NexStarCtl.pm' => '$(INST_LIB)/NexStarCtl.pm'
                         },
    BUILD_REQUIRES    => $required,
    PREREQ_PM         => $required,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'NexStarCtl - API to control NexStar compatible telescopes',
       AUTHOR         => 'Rumen Bogdanovski <rumen@skyarchive.org>') : ()),
);
