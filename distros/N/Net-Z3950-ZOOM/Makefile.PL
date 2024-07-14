# Use: perl Makefile.PL OPTIMIZE="-O0 -g -Wdeclaration-after-statement"
#  or: perl Makefile.PL PREFIX=/home/mike/universe

use 5.008;
use ExtUtils::MakeMaker;
use strict;

my $yazver;
my $yazinc;
my $yazlibs;
system("pkg-config --exists yaz");
if ($? == 0) {
    $yazver = `pkg-config --modversion yaz` or die $!;
    $yazinc = `pkg-config --cflags yaz` or die $!;
    $yazlibs = `pkg-config --libs yaz` or die $!;
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
check_version($yazver, "4.0.0");

# For Windows use
# $yazinc = '-Ic:\yaz\include';
# $yazlibs = 'c:\yaz\lib\yaz.lib';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Z3950::ZOOM',
    VERSION_FROM      => 'lib/Net/Z3950/ZOOM.pm', # finds $VERSION
    PREREQ_PM         => { "MARC::Record" => 1.38 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Z3950/ZOOM.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Taylor <mike@>') : ()),
    LIBS              => [ $yazlibs ], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    INC               => $yazinc, # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
# Use this to test for illegal code that GCC stupidly permits by default:
#   OPTIMIZE          => "-Wdeclaration-after-statement -g -O0",
    EXE_FILES    => [ 'samples/zoom/zselect', 'samples/zoom/zoomdump',
		      'samples/zoom/zoom-delete-records' ],
);


# Fix up the generated Makefile by deleting the standard `test` rule.
system(q[perl -ni -e 'print unless /^\t/ and $discard or $discard = /^test ::/' Makefile]);



sub check_version {
    my($got, $want) = @_;

    my($gmajor, $gminor, $gtrivial) = ($got =~ /(\d+)\.(\d+)\.(\d+)/);
    my($wmajor, $wminor, $wtrivial) = ($want =~ /(\d+)\.(\d+)\.(\d+)/);
    if (($gmajor < $wmajor) ||
	($gmajor == $wmajor && $gminor < $wminor) ||
	($gmajor == $wmajor && $gminor == $wminor && $gtrivial < $wtrivial)) {
	print <<__EOT__;
*** ERROR!
ZOOM-Perl requires at least version $want of YAZ,
but you only have version $got.
__EOT__
	exit 1;
    }
}


sub MY::postamble { <<__EOT__
debian: debian/output

debian/output:
	dpkg-buildpackage -us -uc -rfakeroot -d
	rm -rf debian/output
	mkdir debian/output
	mv ../libnet-z3950-zoom-perl* debian/output

debclean:
	rm -rf debian/libnet-z3950-zoom-perl debian/output

test:
	\@echo '*** Starting yaz-ztest server for tests'
	\@yaz-ztest -w t -v none \@:9996 & PID=\$\$!; set -x; \$(MAKE) \$(TEST_TYPE); kill \$\$PID
__EOT__
}
