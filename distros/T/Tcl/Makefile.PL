# before running this script make sure you have 'tclsh' in your path, 
# and this 'tcl' distribution is the required one.

use strict;
use Getopt::Long;
use ExtUtils::MakeMaker;
use Config;

my $arch;
my $stub = "tclstub8.4";

# These need updating as more platforms are added to tcl-core/ area
if ($^O eq "MSWin32") {
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
} elsif ($^O eq "linux" or $^O eq "cygwin") {
    $arch = "$^O-i686" if ($Config{archname} =~ /i\d86/);
    $arch = "$^O-ia64" if ($Config{archname} =~ /ia64/i);
    $arch = "$^O-x86_64" if ($Config{archname} =~ /x86_64/);
}

sub _die ($) {
    # CPAN smokers report FAIL if Makefile.PL dies, it should exit with status 0
    my $err = shift;
    warn $err;
    exit 0;
}

my $tclsh_default = 'tclsh';
# for FreeBSD users, try to guess their name for tclsh; see ticket 6086
if ($^O eq 'freebsd') {
    for my $ver (qw(9.0 8.7 8.6 8.5 8.4 8.3 8.2 8.1 8.0)) {
       system "which tclsh$ver >/dev/null 2>&1";
       if ($? == 0) {
	    $tclsh_default = "tclsh$ver"; # ok will use that as default
	    last;
	}
    }
}

GetOptions(
   "tclsh=s",     \(my $tclsh=$tclsh_default),
   "tclconfig=s", \ my $tclconfig,
   "usestubs!",   \(my $usestubs = 1),
	# we prefer usestubs, but on windows default is to not use them, because
	# stubs lib that come with AS TCL is impossible to link with GCC which 
	# comes with strawberry perl; Have a ticket for this; (XXX) VKON 27-06-2018
	#
	# ... also any other $^O which we do not have in 'tcl-core' dir
	# except for freebsd and netbsd and openbsd
   "library=s",   \ my $libpath,
   "include=s",   \ my $incpath,
   "define=s",    \(my $defs=''),
   "help!",       \ my $help,   
) || usage();
usage() if $help;
sub usage {
    _die <<'EOT';
Most common usage:
 perl Makefile.PL          

Customised usage:
 perl Makefile.PL      \
  [--nousestubs]       \ # (do not) use the Tcl stubs mechanism
  [--tclsh <path>]     \ # Use this tclsh executable as a base to find the lib info needed
  [--tclconfig <path>] \ # Use this Tcl config file (not tclConfig.sh from the tclsh above)
  [--library=...]      \ # Use this specific Tcl library
  [--include=...]      \ # Use this specific include path
  [--define=...]       \ # Use this specific set of defines
  [--help]             \ # --help
  [<makemaker opts>]     # e.g. LINKTYPE=STATIC

For compilation against tcl at given specific location
 perl Makefile.PL --library=-l/path/to/tcl(stub).a         \
    --include=-I/path/to/tcl/include                       \
    --define="-DLIB_RUNTIME_DIR=... -DTCL_LIB_FILE=..."

--tclsh option is mostly for FreeBSD users, who have tclsh86 or alike;
however default autodetection should be fine with freebsd as well.
EOT
}

my @extraargs;
if ($usestubs) {
    $defs .= " -DUSE_TCL_STUBS";
}

# If using stubs, we will set the LIB_RUNTIME_DIR and TCL_LIB_FILE
# to point to the install location as the default dll to load.

if (defined($libpath) && defined($incpath)) {
    # do nothing - set on command line
} else {
    # otherwise we *require* working tclsh; to avoid bogus FAIL reports
    # even on $^O eq 'darwin'
    # When user has its own tclConfig.sh with --tclconfig=..., then we
    # overwrite values in %tclcfg

    my $tclcfg = `$tclsh tclcfg.tcl`;
    _die "error starting $tclsh: \$?=$?; \$!=$!\n" if $tclcfg eq ''; # can't check $?, BUG 133463
    print $tclcfg;

    my %tclcfg = $tclcfg =~ /^([^=]+)=(.*?)$/gm;

    if ($^O eq 'darwin' && !defined($tclconfig)) {
        $tclconfig = $tclcfg{'tclConfig.sh'};
    }

    if (0 && !defined($tclconfig) && $arch && $usestubs) {
	$incpath = "-Itcl-core/include";
	$libpath = "-Ltcl-core/$arch -l$stub";
	if ($^O eq 'darwin') {
	    # darwin has a broken ranlib that requires you to run it anytime
	    # you copy an archive file, so ensure ours is up-to-date
	    system("ranlib tcl-core/$arch/libtclstub8.4.a");
	    system("git update-index --assume-unchanged tcl-core/$arch/libtclstub8.4.a")
		if -d ".git";
	    # OS X also requires the Carbon framework by default
	    $libpath .= " -framework Carbon";
	}
    } elsif ($tclconfig) {
	_die "Tcl config file '$tclconfig' not found\n" unless (-f $tclconfig);

	# Retrieve all info based on tclConfig.sh
	process_tclconfig($tclconfig, \%tclcfg);

	$libpath = $usestubs ? $tclcfg{TCL_STUB_LIB_SPEC} : $tclcfg{TCL_LIB_SPEC};
	$incpath = $tclcfg{TCL_INCLUDE_SPEC};

	# https://www.cpantesters.org/cpan/report/18397198-6bf4-1014-85e5-4e79f459b9c5
	# Tcl.xs:32:10: fatal error: tcl.h: No such file or directory
	if ($incpath) {
	    my @tclh = grep {-f "$_/tcl.h"} $incpath=~/-I(\S+)/g;
	    if ($#tclh==-1) {
		_die "incpath $incpath from your tclconfig $tclconfig does not provide tcl.h"
	    }
	} else {_die "can not figure out incpath from your tclconfig $tclconfig"}

	if ($usestubs) {
	    if ($^O eq 'darwin' && $tclcfg{TCL_STUB_LIB_PATH} =~ /\.framework/ ) {
		(my $fmk = $tclcfg{TCL_STUB_LIB_PATH}) =~ s/(?<=\.framework).*//;
		$defs .= " -DLIB_RUNTIME_DIR=\\\"$fmk\\\"";
		@extraargs = (dynamic_lib => {OTHERLDFLAGS => "-framework Carbon"});
	    } else {
		$defs .= " -DLIB_RUNTIME_DIR=\\\"$tclcfg{TCL_EXEC_PREFIX}".($^O eq 'MSWin32'?'':'/lib')."\\\"";
	    }
	    $defs .= " -DTCL_LIB_FILE=\\\"$tclcfg{TCL_LIB_FILE}\\\"";
	}
    } else {
	# no --tclconfig=... -> get values from ./tclcfg.tcl
	process_tclconfig($tclcfg{'tclConfig.sh'}, \%tclcfg);
	$libpath = $usestubs ? "$tclcfg{TCL_LIB_SPEC} $tclcfg{TCL_STUB_LIB_SPEC}" : $tclcfg{TCL_LIB_SPEC};
	$incpath = $tclcfg{TCL_INCLUDE_SPEC};
	if ($incpath) {
	    my @tclh = grep {-f "$_/tcl.h"} $incpath=~/-I(\S+)/g;
	    if ($#tclh==-1) {
		warn "incpath $incpath from your tclconfig $tclconfig does not provide tcl.h";
		# on windows users tend to not have correctly edited include path, like this:
		# -I/C/BawtBuilds/TclMinimal/TclMinimal-8.6.12/Windows/x86/Release/Install/Tcl/include
		# help them
		if ($^O eq 'MSWin32') {
		    $tclcfg{'tclConfig.sh'} =~ /^(.*)[\\\/][^\\\/]+$/;
		    $incpath = "-I$1/../include";
		    $libpath = "-L$1 $libpath";
		    # TODO: check whether those dirs has proper tcl.h and .a/.lib files
		} else {
		    # TODO: use tcl.h and library from tcl-core directory
		    _die "can't continue";
		}
	    }
	}
	#?? $defs .= " -DLIB_RUNTIME_DIR=\\\"$1/lib\\\"" if $usestubs;
	$tclcfg{TCL_LIB_FILE} = $tclcfg{TCL_DLL_FILE} if $^O eq 'MSWin32'; # HACK: WHY TF this is in tclConfig.sh on win32??
	$defs .= " -DTCL_LIB_FILE=\\\"$tclcfg{TCL_LIB_FILE}\\\"";
    }
    # version must be 8.4+
    _die "Tcl requires Tcl v8.4 or greater, found '$tclcfg{tcl_version}'\n"
	if (defined $tclcfg{tcl_version} && $tclcfg{tcl_version} <8.4);
}

print "LIBS   = $libpath\n";
print "INC    = $incpath\n";
print "DEFINE = $defs\n";
print "tclConfig.sh = ", $tclconfig || "", "\n";

if ($^O eq 'darwin') {
    if ($libpath =~ /-framework/) {
	# Frameworks require slightly different compile options
	@extraargs = (dynamic_lib => {OTHERLDFLAGS => $libpath});
	$libpath = "";
    }
}

my $mm = WriteMakefile(
    NAME => "Tcl",
    VERSION_FROM => 'Tcl.pm',
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.006',
    ABSTRACT_FROM => 'Tcl.pm',
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/vadrerko/tcl.pm/issues',
            },
            repository => {
                type => 'git',
                web => 'https://github.com/vadrerko/tcl.pm',
                url => 'https://github.com/vadrerko/tcl.pm.git',
            },
            MailingList => 'mailto:tcltk@perl.org',
        }
    },
    LIBS => ["$libpath"],
    INC => "$incpath",
    DEFINE => $defs,
    @extraargs,
);

sub process_tclconfig {
    # Process a tclConfig.sh file for build info
    my $tclconf = shift;
    my $hashref = shift;

    if ($^O eq 'MSWin32') {
	    open my $fh, $tclconf or _die "error opening file '$tclconf': $!\n";
	    print "Using config data in $tclconf\n";
	    my %vars = (join '', <$fh>) =~ /^(\w+)=['"]?(.*?)["']?$/gm;
	    $hashref->{$_} = $vars{$_} for keys %vars;
	    $hashref->{TCL_EXEC_PREFIX}=~y{\\}{/}; # hack for MSWin32

	    for my $k (keys %$hashref) {
		# Handle sh subs like ${TCL_DBGX}
		$hashref->{$k} =~ s/\$\{(\w+)\}/(exists $hashref->{$1} ? $hashref->{$1} : $&)/eg;
		# Handle any cygdrive-style paths
		$hashref->{$k} =~ s{/cygdrive/(\w)/}{$1:/}ig;
	    }

    } else {
	    # on non-windows we should execute with shell
	    # because we could have there
	    # #! /bin/sh
	    # . /usr/lib/`dpkg-architecture -qDEB_HOST_MULTIARCH`/tcl8.6/tclConfig.sh
	    -f $tclconf or _die "no file '$tclconf'\n";
	    my $vars2get = join ';', map {qq/echo 'echo "$_=\$$_"'/} qw (
		TCL_STUB_LIB_PATH
		TCL_STUB_LIB_SPEC
		TCL_LIB_SPEC
		TCL_LIB_FILE
		TCL_DLL_FILE
		TCL_INCLUDE_SPEC
		TCL_EXEC_PREFIX
	    );
	    my %vars = `(cat $tclconf; $vars2get) | sh` =~ /^(\w+)=(.*)$/mg;
	    $hashref->{$_} = $vars{$_} for keys %vars;
    }
    $hashref->{tcl_version} = $hashref->{TCL_VERSION} if exists $hashref->{TCL_VERSION};
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

