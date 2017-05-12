#!perl -w

# before running this script make sure you have 'tclsh' in your path, 
# and this 'tcl' distribution is required one.
# FreeBSD users may want to modify name of tcl interpreter (this is
# $tclsh variable below) as long as 'tclsh' does not work in their case

use strict;
use Getopt::Long qw(GetOptions);
use ExtUtils::MakeMaker;
use Config;

my $tclsh = 'tclsh';
my $tclconfig;
my $buildspec;
my $usestubs = ($^O eq 'MSWin32' ? 0 : 1);
my $libpath;
my $incpath;
my $defs = "";
my $buildtype = "";
my @extraargs;

my $arch;
my $stub = "tclstub8.4";

# These need updating as more platforms are added to tcl-core/ area
if ($^O eq "aix") {
    $arch = "aix";
} elsif ($^O eq "MSWin32") {
    $stub = "tclstub84";
    $arch = "win32-x86" if ($Config{archname} =~ /-x86-/);
    $arch = "win32-x64" if ($Config{archname} =~ /-x64-/);
} elsif ($^O eq "darwin") {
    $arch = "darwin-universal";
} elsif ($^O eq "solaris") {
    $arch = "$^O-x86" if ($Config{archname} =~ /86/);
    $arch = "$^O-sparc" if ($Config{archname} =~ /sun4/);
} elsif ($^O eq "aix") {
    $arch = "$^O";
} elsif ($^O eq "hpux") {
    $arch = "$^O-ia64" if ($Config{archname} =~ /ia64/i);
    $arch = "$^O-parisc" if ($Config{archname} =~ /pa-risc/i);
} elsif ($^O eq "linux") {
    $arch = "$^O-i686" if ($Config{archname} =~ /i\d86/);
    $arch = "$^O-ia64" if ($Config{archname} =~ /ia64/i);
    $arch = "$^O-x86_64" if ($Config{archname} =~ /x86_64/);
} elsif ($^O eq "cygwin") {
    $tclconfig = '/usr/lib/tclConfig.sh';
}

sub _die ($) {
    # now CPAN smokers report FAIL if Makefile.PL dies, it
    # should exit with status 0
    my $err = shift;
    warn $err;
    exit 0;
}

GetOptions("tclsh=s", \$tclsh,         # Use this tclsh executable as a
                                       # base to find the lib info needed
	   "tclconfig=s", \$tclconfig, # Use the specified Tcl config file
                                       # instead of basing the values on
                                       # the tclsh exe found
	   "buildspec", \$buildspec,   # Used with --tclconfig, use the
                                       # build (instead of install) values
                                       # for determining lib info
	   "usestubs!", \$usestubs,    # we want to use the Tcl stubs
                                       # mechanism by default
	   "library=s", \$libpath,     # Use this specific Tcl library
	   "include=s", \$incpath,     # Use this specific include path
	   "define=s", \$defs,         # Use this specific set of defines
	  )
    || _die <<EOT;

Usage: perl Makefile.PL [--tclsh <path>] [--tclconfig <path>]
                        [--buildspec] [--nousestubs] [<makemaker opts>...]

or for expert compilation:

       perl --library=-l/path/to/tcl(stub).a --include=-I/path/to/tcl/include
            --define="-DLIB_RUNTIME_DIR=... -DTCL_LIB_FILE=..."

EOT

if ($usestubs) {
    $defs .= " -DUSE_TCL_STUBS";
    $buildtype = "stub";
}

# If using stubs, we will set the LIB_RUNTIME_DIR and TCL_LIB_FILE
# to point to the install location as the default dll to load.

if (defined($libpath) && defined($incpath)) {
    # do nothing - set on command line
} elsif (!defined($tclconfig) && defined($arch) && $usestubs) {
    $incpath = "-Itcl-core/include";
    $libpath = "-Ltcl-core/$arch -l$stub";
    if ($^O eq 'darwin') {
	# OS X also requires the Carbon framework by default
	$libpath .= " -framework Carbon";
    }
} elsif ($tclconfig || $^O eq 'darwin') {
    unless ($tclconfig) {
       open(TCLSH, "$tclsh tclcfg.tcl |") or _die "error starting tclsh: $!\n";
       my $tclcfg = join '', <TCLSH>;
       close(TCLSH);
       my %tclcfg = $tclcfg =~ /^([^=]+)=(.*?)\n/gm;
       $tclconfig = $tclcfg{'tclConfig.sh'};
    }
    _die "Tcl config file '$tclconfig' not found\n" unless (-f $tclconfig);

    # Retrieve all info based on tclConfig.sh
    my $variant    = ($usestubs ? "_STUB" : "");
    $variant       = "_BUILD$variant" if $buildspec;
    my $libspecvar = "TCL${variant}_LIB_SPEC";
    my %tclcfg;
    process_tclconfig($tclconfig, \%tclcfg);
    _die "Tcl requires Tcl v8.4 or greater, found '$tclcfg{TCL_VERSION}'\n"
	unless (defined $tclcfg{'TCL_VERSION'}
		&& $tclcfg{'TCL_VERSION'} >= 8.4);
    $libpath = $tclcfg{$libspecvar};
    $incpath = $tclcfg{'TCL_INCLUDE_SPEC'};
    if ($usestubs) {
	if ($^O eq 'MSWin32') {
	    $defs .= " -DLIB_RUNTIME_DIR=\\\"$tclcfg{'TCL_EXEC_PREFIX'}/bin\\\"";
	    $defs .= " -DTCL_LIB_FILE=\\\"$tclcfg{'TCL_DLL_FILE'}\\\""; 
	} elsif ($^O eq 'darwin' && $tclcfg{'TCL_STUB_LIB_PATH'} =~ /\.framework/ ) {
	    (my $fmk = $tclcfg{'TCL_STUB_LIB_PATH'}) =~ s/(?<=\.framework).*//;
	    $defs .= " -DLIB_RUNTIME_DIR=\\\"$fmk\\\"";
	    $defs .= " -DTCL_LIB_FILE=\\\"$tclcfg{'TCL_LIB_FILE'}\\\"";
	    @extraargs = (dynamic_lib => {OTHERLDFLAGS => "-framework Carbon"});
	} else {
	    $defs .= " -DLIB_RUNTIME_DIR=\\\"$tclcfg{'TCL_EXEC_PREFIX'}/lib\\\"";
	    $defs .= " -DTCL_LIB_FILE=\\\"$tclcfg{'TCL_LIB_FILE'}\\\""; 
	}
    }
} else {
    open(TCLSH, "$tclsh tclcfg.tcl |") or _die "error starting tclsh: $!\n";
    my $tclcfg = join '', <TCLSH>;
    close(TCLSH);
    print $tclcfg;
    my %tclcfg = $tclcfg =~ /^([^=]+)=(.*?)\n/gm;

    # This is to allow propagation of this value to sub-Makefile.PLs
    $ENV{'TCLSH_PROG'} = $tclsh;

    if (0 && -f $tclcfg{'tclConfig.sh'}) {
	# Retrieve all info based on tclConfig.sh
	# Don't do this unless the user passes --tclconfig
	process_tclconfig($tclcfg{'tclConfig.sh'}, \%tclcfg);
	# libpath/incpath vars need to be set here if used ...
    } else {
	my $tclver = $tclcfg{tcl_version};

	# currently version must be 8.4+
	my ($vmaj,$vmin) = ($tclver =~ /^(\d+)\.(\d+)/);
	_die "Tcl requires Tcl v8.4 or greater, found '$vmaj.$vmin'\n"
	    if ($vmaj < 8 || ($vmaj == 8 && $vmin < 4));

	if ($tclcfg{tcl_library} =~ /^(.*)[\\\/]lib[\\\/]/) {
	    $libpath = "-L$1/lib";
	    $incpath = "-I$1/include";
	    $defs .= " -DLIB_RUNTIME_DIR=\\\"$1/lib\\\"" if $usestubs;
	}

	if ($^O eq 'MSWin32') {
	    $tclver=~s/\.//;
	    $defs .= " -DTCL_LIB_FILE=\\\"tcl$tclver.dll\\\"" if $usestubs; 
	}
	elsif ($^O eq 'freebsd') {
	    $tclver=~s/\.//;
	    $tclsh=~/([\d.]+)$/ and $incpath .= " -I/usr/local/include/tcl$1";
	    $defs .= " -DTCL_LIB_FILE=\\\"libtcl$tclver.so\\\"" if $usestubs; 
	}
	elsif ($^O eq 'hpux') {
	    #$tclver = '';
	    $defs .= " -DTCL_LIB_FILE=\\\"libtcl$tclver.sl\\\"" if $usestubs;
	}
	else {
	    #$tclver = '';
	    $defs .= " -DTCL_LIB_FILE=\\\"libtcl$tclver.so\\\"" if $usestubs; 
	}
	$libpath .= " -ltcl$buildtype$tclver";
    }
}

print "LIBS   = $libpath\n";
print "INC    = $incpath\n";
print "DEFINE = $defs\n";

if ($^O eq 'darwin') {
    # darwin has a broken ranlib that requires you to run it anytime
    # you copy an archive file, so ensure ours it up-to-date
    system("ranlib tcl-core/$arch/libtclstub8.4.a");
    system("git update-index --assume-unchanged tcl-core/$arch/libtclstub8.4.a")
	if -d ".git";
    if ($libpath =~ /-framework/) {
	# Frameworks require slightly different compile options
	@extraargs = (dynamic_lib => {OTHERLDFLAGS => $libpath});
	$libpath = "";
    }
}

#print <<"#EOS";
WriteMakefile(
    NAME => "Tcl",
    VERSION_FROM => 'Tcl.pm',
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.006',
    ABSTRACT_FROM => 'Tcl.pm',
    META_MERGE => {
        resources => {
            repository => 'http://github.com/gisle/tcl.pm',
            MailingList => 'mailto:tcltk@perl.org',
        }
    },
    LIBS => ["$libpath"],
    INC => "$incpath",
    DEFINE => $defs,
    @extraargs,
);

#EOS

sub process_tclconfig {
    # Process a tclConfig.sh file for build info
    my $tclconfig = shift;
    my $hashref   = shift;

    open(TCLSH, $tclconfig)
	or _die "error opening file '$tclconfig': $!\n";
    print "Using config data in $tclconfig\n";
    my $tclcfg = join '', <TCLSH>;
    close(TCLSH);
    %$hashref = $tclcfg =~ /^(\w+)=['"]?(.*?)["']?\n/gm;

    for my $k (keys %$hashref) {
	# Handle sh subs like ${TCL_DBGX}
	$hashref->{$k} =~ s/\$\{(\w+)\}/(exists $hashref->{$1} ? $hashref->{$1} : $&)/eg;
	# Handle any cygdrive-style paths
	$hashref->{$k} =~ s,/cygdrive/(\w)/,$1:/,ig;
    }
}

sub MY::libscan {
    my($self, $path) =@_;
    return '' if $path =~ /\.pl$/i;
    return $path;
}

BEGIN {
    # compatibility with older versions of MakeMaker
    my $developer = -f ".git";
    my %mm_req = (
        LICENCE => 6.31,
        META_MERGE => 6.45,
        META_ADD => 6.45,
        MIN_PERL_VERSION => 6.48,
    );
    undef(*WriteMakefile);
    *WriteMakefile = sub {
        my %arg = @_;
        for (keys %mm_req) {
            unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
                warn "$_ $@" if $developer;
                delete $arg{$_};
            }
        }
        ExtUtils::MakeMaker::WriteMakefile(%arg);
    };
}

