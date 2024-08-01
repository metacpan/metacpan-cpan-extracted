# Use: perl Makefile.PL OPTIMIZE="-O0 -g -Wdeclaration-after-statement"
#  or: perl Makefile.PL PREFIX=/home/mike/universe

use 5.008;
use ExtUtils::MakeMaker;
use strict;

my $yazver;
my $yazinc;
my $yazlibs;
system("pkg-config --exists yaz-server");
if ($? == 0) {
    $yazver = `pkg-config --modversion yaz-server` or die $!;
    $yazinc = `pkg-config --cflags yaz-server` or die $!;
    $yazlibs = `pkg-config --libs yaz-server` or die $!;
} else {
    $yazver = `yaz-config --version`;
    $yazinc = `yaz-config --cflags servers`;
    $yazlibs = `yaz-config --libs server`;
    if (!$yazver || (!$yazinc && !$yazlibs)) {
       die qq[
ERROR: Unable to call script: yaz-config
If you are using a YAZ installation from the Debian package "yaz", you
will also need to install "libyaz-dev" in order to build the
SimpleServer module.
];
   }
}

chomp($yazver);
check_version($yazver, "5.27.0");

# For Windows use
# $yazinc = '-Ic:\yaz\include';
# $yazlibs = 'c:\yaz\lib\yaz3.lib';

WriteMakefile(
    'NAME'	=> 'Net::Z3950::SimpleServer',
    'VERSION_FROM' => 'SimpleServer.pm', # finds $VERSION
    'LIBS'	=> [$yazlibs],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> $yazinc,     # e.g., '-I/usr/include/other' 
#    OPTIMIZE   => "-Wdeclaration-after-statement -g -O0",
);


sub check_version {
    my($got, $want) = @_;

    my($gmajor, $gminor, $gtrivial) = ($got =~ /(\d+)\.(\d+)\.(\d+)/);
    my($wmajor, $wminor, $wtrivial) = ($want =~ /(\d+)\.(\d+)\.(\d+)/);
    if (($gmajor < $wmajor) ||
	($gmajor == $wmajor && $gminor < $wminor) ||
	($gmajor == $wmajor && $gminor == $wminor && $gtrivial < $wtrivial)) {
	print <<__EOT__;
*** ERROR!
Net::Z3950::SimpleServer requires at least version $want of YAZ,
but you only have version $got.
__EOT__
	exit 1;
    }
}

# When running on MacOS Monterey 12.7.5, "make test" fails with
# Can't load 'blib/arch/auto/Net/Z3950/SimpleServer/SimpleServer.bundle' for module Net::Z3950::SimpleServer [...] (relative path not allowed in hardened program)
# We can prevent this by overriding the target with an absolute path:
#
# HOWEVER, doing so causes the "make install" phase to fail: see
# https://folio-org.atlassian.net/browse/ZF-103
# So until we figure out something better, we'll just comment this out.
#sub MY::postamble { 'INST_ARCHLIB = `pwd`/blib/arch' }
