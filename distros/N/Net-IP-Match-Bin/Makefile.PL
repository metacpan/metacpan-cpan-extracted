use 5.007;
use Config qw(%Config);
use ExtUtils::MakeMaker;

my $DEFS = '';
my $OS = $^O;
if ($OS =~ /solaris/i) {
    $DEFS .= " -DSOLARIS";
} elsif ($OS =~ /linux/i) {
    $DEFS .= " -DLINUX";
} elsif ($OS =~ /cygwin/i) {
    $DEFS .= " -DCYGWIN";
}
my $pv = $] * 1000000;
$DEFS .= " -DPVER=$pv";

my $SRCS = [];
if (test_compile()) {
    $SRCS = ["Bin.c"];
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::IP::Match::Bin',
    VERSION_FROM      => 'lib/Net/IP/Match/Bin.pm', # finds $VERSION
    C			=> $SRCS,
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/IP/Match/Bin.pm', # retrieve abstract from module
       AUTHOR         => 'Tomo <tomo_at_cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => "$DEFS", # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);


sub test_compile {
    open(CONFTEST, ">conftest.c") or die "$!";
    print CONFTEST <<'EOT'; close(CONFTEST);
/* test program */
int
main ()
{

  ;
  return 0;
}
EOT

    my $cc_cmd = "$Config{cc}";
    my $exe = "conftest$Config{exe_ext}";
    $cc_cmd .= " -o $exe";

    my $rc;
    $rc = system("$cc_cmd conftest.c");
    if ($rc) {
	print "Can't compile test program rc=$rc\n\n";
	unlink("conftest.c", $exe, "conftest$Config{obj_ext}");
	return 0;
    }
    $rc = system("./$exe");
    unlink("conftest.c", $exe, "conftest$Config{obj_ext}");
    return 1 unless $rc;

    if ($rc > 0x80) {
	(my $cp = $rc) >>= 8;
	print "Test program exit status was $cp\n";
    }
    if ($rc & 0x80) {
	$rc &= ~0x80;
	unlink("*core") && print "Core dump deleted\n";
    }
    print "signal $rc\n" if $rc && $rc < 0x80;
    return 0;    
}
