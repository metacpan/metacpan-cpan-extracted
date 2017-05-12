use 5.006;
use ExtUtils::MakeMaker;
use File::Basename;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/rrdtool-oo-perl',
        },
    }
};

# Check if RRDs is installed

eval "use RRDs 1.2011";

    # (1) libcgi is missing on most Linux/FreeBSD systems, and we
    #     don't need it anyway.
    # (2) as of rrdtool-1.2.11, tcl libs didn't compile, so let's
    #     leave them out.
my $CONFIGURE_OPTS = "--enable-perl-site-install --prefix=/usr --disable-tcl --disable-rrdcgi";

my $DIST_URL = 
"http://oss.oetiker.ch/rrdtool/pub/rrdtool.tar.gz";

if($@) {
    print <<EOT;
This module requires rrdtool 1.2.x and the RRDs module to be 
installed. They are available in the rrdtool distribution:
 $DIST_URL
EOT

    $| = 1;
    my $in = prompt ("Do you want me to install it for you right now (y/n)?","n");
    chomp $in;
    if($in =~ /^\s*$/ or $in =~ /y/i) {
        if($> != 0) {
            die "\nYou need to be root to do this.\n";
        }
        eval { install_RRDs() };
        if($@) {
            print $@;
            note();
            exit 0;
        }
    } else {
        note();
        exit 0;
    }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RRDTool::OO',
    VERSION_FROM      => 'lib/RRDTool/OO.pm', # finds $VERSION
    PREREQ_PM         => {
                         Log::Log4perl => '0.40',
                         RRDs          => 0,
                         Storable      => 0,
                         }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RRDTool/OO.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Schilli <m@perlmeister.com>') : ()),
);

##################################################################
sub install_RRDs {
##################################################################

    require LWP::Simple;
    print STDERR "Downloading ... ";
    LWP::Simple::getstore($DIST_URL, basename($DIST_URL)) or 
        die "Cannot download $DIST_URL ($!)";
    print STDERR "done.\n";

    system("gzip -dc rrdtool.tar.gz | tar xfv -; cd `ls -t | grep rrdtool | grep -v gz | head -1`; ./configure $CONFIGURE_OPTS; make; cd bindings/perl-shared; perl Makefile.PL; make; make test; make install") and die "Install failed: $!";

}

##################################################################
sub note {
##################################################################
    print "################################################\n";
    print "# Please check the INSTALLATION section in the #\n";
    print "# RRDTool::OO manual page.                     #\n";
    print "# You can download the rrdtool library at      #\n";
    print "# $DIST_URL\n";
    print "# and compile it using                         #\n";
    print "#   configure $CONFIGURE_OPTS\n";
    print "#   make\n";
    print "#   cd perl-shared; perl Makefile.PL; make install\n";
    print "################################################\n";
}

