use strict;
use Config;
use Cwd;
use ExtUtils::MakeMaker;
eval "use ExtUtils::MakeMaker::Coverage";
use File::Spec;


my ($DEBUG, %options, $DEVNULL, $is_Win32, $has_Win32);

if ($^O eq 'MSWin32') {
    $options{LIBS}    = '-lwpcap';
    $options{DEFINE}  = '-DWINSOCK2_H_REQUESTED -DWPCAP -DHAVE_REMOTE';

    # patch ActivePerl CORE/sys/socket.h
    win32_sys_socket_patch();
}
elsif ($^O eq 'cygwin') {
    $options{LIBS}    = '-lwpcap';
    $options{DEFINE}  = '-DWPCAP -D_CYGWIN -DWIN32';

    cygwin_pcap_headers();
}
else {
    $options{CCFLAGS} = "$Config{ccflags} -Wall -Wwrite-strings"
        if $Config{ccname} eq "gcc" and $] >= 5.006;
    $options{LIBS}    = '-lpcap';
}

for my $arg (@ARGV) {
    my($key,$val) = split /=/, $arg, 2;
    $options{$key} = length $options{$key} ? "$val $options{$key}" : $val;
}


# The detection logic is: 
#   1. first try to check if the pcap library is available; 
#   2. then try to use the pcap_lib_version() function which is present 
#      in recent version and is the only function that can be called 
#      with no argument.
if ($has_Win32) { # ActivePerl, Cygwin
    die <<"REASON" unless have_library('wpcap', 'blank', 'pcap');
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The WinPcap driver is not installed on this machine. \a

Please get and install the WinPcap driver and DLLs (auto-installer) from
  http://www.winpcap.org/install/
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
REASON

    die <<"REASON" unless have_library('wpcap', 'pcap_lib_version', 'pcap');
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
You appear to lack the WinPcap developer pack. \a

If it is installed in a non-standard location, please try setting the LIBS 
and INC values on the command line.  For instance, if you have unziped the 
developer's pack in C:\\WpdPack, you should execute: 

    perl Makefile.PL INC=-IC:/WpdPack/Include "LIBS=-LC:/WpdPack/Lib -lwpcap"

Or get and install the WinPcap developer's pack from
  http://www.winpcap.org/install/
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
REASON

} else { # other systems (Unix)
    die <<"REASON" unless have_library('pcap');
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
You appear to lack the pcap(3) library. \a

If it is installed in a non-standard location, please try setting the LIBS 
and INC values on the command line.

Or get the sources and install the pcap library from http://www.tcpdump.org/

If you install the pcap library using a system package, make sure to also 
install the corresponding -devel package, which contains the C headers needed 
to compile this module. 
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
REASON

    die <<"REASON" unless have_library('pcap', 'pcap_lib_version');
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
You appear to have an old version of the pcap library. \a

This module need a recent version of the pcap library in order to provide 
access to all its features. You can still compile it with your old pcap 
library but some functions won't be available, and trying to use them in 
Perl programs will generate errors. Programs only using the old functions 
should perform as previously. If not, don't hesitate to fill a bug. 

You can get the latest sources of the pcap library at http://www.tcpdump.org/

If you install the pcap library using a system package, make sure to also 
install the corresponding -devel package, which contains the C headers needed 
to compile this module. 
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
REASON
}

# Now trying to detect which functions are actually available. 
# We have to do this because the pcap library still doesn't have any macro 
# to identify its API version and the pcap_lib_version() is only available 
# since version 0.8 or so. Therefore we add defines in order to replace 
# missing functions with croaking stubs. 
# We also store the list of available functions in a file for skipping the 
# corresponding tests. 
my @funcs = have_functions(find_functions());
$options{DEFINE} .= cpp_defines(@funcs);
open(FUNCS, '>funcs.txt') or warn "warning: can't write 'funcs.txt': $!\n";
print FUNCS join("\n", @funcs), "\n";
close(FUNCS);


WriteMakefile(
    NAME            => 'Net::Pcap',
    LICENSE         => 'perl',
    AUTHOR          => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    DISTNAME        => 'Net-Pcap',
    VERSION_FROM    => 'Pcap.pm',
    ABSTRACT_FROM   => 'Pcap.pm',
    MIN_PERL_VERSION=> 5.6.1,
    PL_FILES        => {}, 
    EXE_FILES       => [ 'bin/pcapinfo' ], 
    PREREQ_PM       => {
        # module prereqs
        'Carp'          => '0',
        'XSLoader'      => '0',

        # pcapinfo prereqs
        'Sys::Hostname' => '0',

        # build/test prereqs
        'Socket'        => '0',
        'Test::More'    => '0.45',
    },
    META_MERGE          => {
        resources       => {
            repository  => "https://github.com/maddingue/Net-Pcap",
        },
    },
    dist        => { 'COMPRESS' => "gzip -9f", 'SUFFIX'   => "gz" }, 
    clean       => { FILES => 'Net-Pcap-* macros.all' }, 
    %options,        # appropriate CCFLAGS, LDFLAGS and Define's
);

if (eval { require ExtUtils::Constant; 1 }) {
    # If you edit these definitions to change the constants used by this module,
    # you will need to use the generated const-c.inc and const-xs.inc
    # files to replace their "fallback" counterparts before distributing your
    # changes.
    my @names = (qw(
        BPF_A BPF_ABS BPF_ADD BPF_ALIGNMENT BPF_ALU BPF_AND BPF_B
        BPF_DIV BPF_H BPF_IMM BPF_IND BPF_JA BPF_JEQ BPF_JGE BPF_JGT
        BPF_JMP BPF_JSET BPF_K BPF_LD BPF_LDX BPF_LEN BPF_LSH
        BPF_MAJOR_VERSION BPF_MAXBUFSIZE BPF_MAXINSNS BPF_MEM
        BPF_MEMWORDS BPF_MINBUFSIZE BPF_MINOR_VERSION BPF_MISC BPF_MSH
        BPF_MUL BPF_NEG BPF_OR BPF_RELEASE BPF_RET BPF_RSH BPF_ST
        BPF_STX BPF_SUB BPF_TAX BPF_TXA BPF_W BPF_X DLT_AIRONET_HEADER
        DLT_APPLE_IP_OVER_IEEE1394 DLT_ARCNET DLT_ARCNET_LINUX
        DLT_ATM_CLIP DLT_ATM_RFC1483 DLT_AURORA DLT_AX25 DLT_CHAOS
        DLT_CHDLC DLT_CISCO_IOS DLT_C_HDLC DLT_DOCSIS DLT_ECONET
        DLT_EN10MB DLT_EN3MB DLT_ENC DLT_FDDI DLT_FRELAY DLT_HHDLC
        DLT_IBM_SN DLT_IBM_SP DLT_IEEE802 DLT_IEEE802_11
        DLT_IEEE802_11_RADIO DLT_IEEE802_11_RADIO_AVS DLT_IPFILTER
        DLT_IP_OVER_FC DLT_JUNIPER_ATM1 DLT_JUNIPER_ATM2
        DLT_JUNIPER_ES DLT_JUNIPER_GGSN DLT_JUNIPER_MFR
        DLT_JUNIPER_MLFR DLT_JUNIPER_MLPPP DLT_JUNIPER_MONITOR
        DLT_JUNIPER_SERVICES DLT_LINUX_IRDA DLT_LINUX_SLL DLT_LOOP
        DLT_LTALK DLT_NULL DLT_OLD_PFLOG DLT_PCI_EXP DLT_PFLOG
        DLT_PFSYNC DLT_PPP DLT_PPP_BSDOS DLT_PPP_ETHER DLT_PPP_SERIAL
        DLT_PRISM_HEADER DLT_PRONET DLT_RAW DLT_RIO DLT_SLIP
        DLT_SLIP_BSDOS DLT_SUNATM DLT_SYMANTEC_FIREWALL DLT_TZSP
        DLT_USER0 DLT_USER1 DLT_USER10 DLT_USER11 DLT_USER12
        DLT_USER13 DLT_USER14 DLT_USER15 DLT_USER2 DLT_USER3 DLT_USER4
        DLT_USER5 DLT_USER6 DLT_USER7 DLT_USER8 DLT_USER9 MODE_CAPT
        MODE_MON MODE_STAT PCAP_ERRBUF_SIZE PCAP_IF_LOOPBACK
        PCAP_VERSION_MAJOR PCAP_VERSION_MINOR OPENFLAG_PROMISCUOUS 
        OPENFLAG_DATATX_UDP OPENFLAG_NOCAPTURE_RPCAP RMTAUTH_NULL RMTAUTH_PWD
        PCAP_SAMP_NOSAMP PCAP_SAMP_FIRST_AFTER_N_MS PCAP_SAMP_1_EVERY_N 
        PCAP_SRC_FILE PCAP_SRC_IFLOCAL PCAP_SRC_IFREMOTE
    ));

    ExtUtils::Constant::WriteConstants(
            NAME         => 'pcap',
            NAMES        => \@names,
            DEFAULT_TYPE => 'IV',
            C_FILE       => 'const-c.inc',
            XS_FILE      => 'const-xs.inc',
    );

    open(MACROS, '>macros.all') or warn "can't write 'macros.all': $!\n";
    print MACROS join $/, @names;
    close(MACROS);
}
elsif (eval "use File::Copy; 1") {
    foreach my $file ('const-c.inc', 'const-xs.inc') {
        my $fallback = File::Spec->catfile('fallback', $file);
        copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
    }
}
else {
    die <<"REASON"
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Your Perl installation lacks both File::Copy and ExtUtils::Constant.\a
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
REASON
}


# The following function patches ActivePerl CORE/sys/socket.h 
sub win32_sys_socket_patch {
    my $sockfile;

    my $ifdef = <<'IFDEF';
/* This file was patched so that WinPcap can use WinSock2.
   The original file was renamed 'socket.h.orig'.
 */
#ifdef WINSOCK2_H_REQUESTED
#include <winsock2.h>
#else
#include <winsock.h>
#endif
/* end of patch */
IFDEF

    foreach (@INC) {  # looking for socket.h
        if (-e $_.'/CORE/sys/socket.h') {
            $sockfile = $_.'/CORE/sys/socket.h';
            last
        }
    }
  
    die "file 'socket.h' not found\n" unless $sockfile;
    open H, "<$sockfile" or die "can't read file '$sockfile': $!\n";
    my $h;
    { local $/; $h = <H>; }  # slurp file
    close H;
  
    if ($h =~ /\#include <winsock2.h>/) {
        print "socket.h already patched... ok\n"
    } else {
        if (rename $sockfile, $sockfile.'.orig') {
            $h =~ s/#include <winsock.h>/$ifdef/;
            open H, "> $sockfile" or die $!;
            print H $h;
            close H;
            print "socket.h patched... ok\n"
        } else {
            print "Unable to patch socket.h\n"
        }
    }
}

# Cygwin and WinPcap are a *very* special case..
sub cygwin_pcap_headers {
    my $incdir = '';
    my $localinc = File::Spec->catdir(getcwd(), 'include');

    for my $i (0..$#ARGV) {
        if($ARGV[$i] =~ /^INC=/) {
            (undef,$incdir) = split /-I/, $ARGV[$i], 2;
            $ARGV[$i] = "INC=-I$localinc";
        }
    }

    eval 'use File::Path';
    mkpath($localinc);

    eval 'use File::Copy';
    for my $file (qw(pcap.h pcap-bpf.h pcap-int.h pcap-stdinc.h Win32-Extensions.h bittypes.h ip6_misc.h)) {
        my $orig = File::Spec->catfile($incdir, $file);
        my $dest = File::Spec->catfile($localinc, $file);
        copy($orig, $dest);
    }
}

# The rest of the code, up to the end of this file, has been copied 
# from XML::LibXML::Common Makefile.PL, then modified in order to 
# make all this detection stuff works under Win32

###################################################################
# Functions
#  - these should really be in MakeMaker... But &shrug;
###################################################################

use Config;
use DynaLoader;
use Symbol;

BEGIN {
    eval 'use Win32';
    $has_Win32 = !$@;
    $is_Win32 = ($^O eq 'MSWin32');
    if ($is_Win32) {
        $DEVNULL = 'DEVNULL';
    } else {
        $DEVNULL = eval { File::Spec->devnull };
        if ($@) { $DEVNULL = '/dev/null' }
    }
}

sub rm_f {
    my @files = @_;
    my @realfiles;

    foreach (@files) {
        push @realfiles, glob($_);
    }

    if (@realfiles) {
        chmod(0777, @realfiles);
        unlink(@realfiles);
    }
}

sub rm_fr {
    my @files = @_;
    my @realfiles;

    foreach (@files) {
        push @realfiles, glob($_);
    }

    foreach my $file (@realfiles) {
        if (-d $file) {
            # warn("$file is a directory\n");
            rm_fr("$file/*");
            rm_fr("$file/.exists");
            rmdir($file) || die "Couldn't remove $file: $!";

        } else {
            # warn("removing $file\n");
            chmod(0777, $file);
            unlink($file);
        }
    }
}

sub xsystem {
    my $command = shift;

    if ($DEBUG) {
        print "\nxsystem: ", $command, "\n";
        if (system($command) != 0) {
            die "system call to '$command' failed";
        }
        return 1;
    }

    open(OLDOUT, ">&STDOUT");
    open(OLDERR, ">&STDERR");
    open(STDOUT, ">$DEVNULL");
    open(STDERR, ">$DEVNULL");
    my $retval = system($command);
    open(STDOUT, ">&OLDOUT");
    open(STDERR, ">&OLDERR");
    die "system call to '$command' failed" if $retval != 0;
    return 1;
}

sub backtick {
    my $command = shift;

    if ($DEBUG) {
        print $command, "\n";
        my $results = `$command`;
        chomp $results;
        die "backticks call to '$command' failed" if $? != 0;
        return $results;
    }

    open(OLDOUT, ">&STDOUT");
    open(OLDERR, ">&STDERR");
    open(STDOUT, ">$DEVNULL");
    open(STDERR, ">$DEVNULL");
    my $results = `$command`;
    my $retval = $?;
    open(STDOUT, ">&OLDOUT");
    open(STDERR, ">&OLDERR");
    die "backticks call to '$command' failed" if $retval != 0;
    chomp $results;
    return $results;
}

sub try_link0 {
    my ($src, $opt) = @_;

    my $cfile = gensym();
    $opt ||= '';
    
    # local $options{LIBS};
    # $options{LIBS} .= $opt;
    unless (mkdir(".testlink", 0777)) {
        rm_fr(".testlink");
        mkdir(".testlink", 0777) || die "Cannot create .testlink dir: $!";
    }
    chdir(".testlink");
    open($cfile, ">Conftest.xs") || die "Cannot write to file Conftest.xs: $!";
print $cfile <<EOT;
#ifdef __cplusplus
extern "C" {
#endif
#ifdef _WIN32
#include <malloc.h>
#endif
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#ifdef __cplusplus
}
#endif

EOT
    print $cfile $src;
    print $cfile <<EOT;

MODULE = Conftest          PACKAGE = Conftest

PROTOTYPES: DISABLE

EOT
    close($cfile);
    open($cfile, ">Conftest.pm") || die "Cannot write to file Conftest.pm: $!";
    print $cfile <<'EOT';
package Conftest;
$VERSION = 1.0;
require DynaLoader;
@ISA = ('DynaLoader');
bootstrap Conftest $VERSION;
1;
EOT
    close($cfile);
    open($cfile, ">Makefile.PL") || die "Cannot write to file Makefile.PL: $!";
    print $cfile <<'EOT';
use ExtUtils::MakeMaker;
my %options;
while($_ = shift @ARGV) {
    my ($k, $v) = split /=/, $_, 2;
    warn("$k = $v\n");
    $options{$k} = $v;
}
WriteMakefile(NAME => "Conftest", VERSION_FROM => "Conftest.pm", %options);
EOT
    close($cfile);
    open($cfile, ">test.pl") || die "Cannot write to file test.pl: $!";
    print $cfile <<EOT;
use Test; BEGIN { plan tests => 1; } END { ok(\$loaded) }
use Conftest; \$loaded++;
EOT
    close($cfile);
    my $quote = $is_Win32 ? '"' : "'";
    xsystem("$^X Makefile.PL " . join(' ', map { "${quote}$_=$options{$_}${quote}" } keys %options));
    xsystem("$Config{make} test ${quote}OTHERLDFLAGS=${opt}${quote}");
} # end try_link0

sub try_link {
    my $start_dir = cwd();
    my $result = eval { try_link0(@_) };
    warn $@ if $DEBUG && $@;
    chdir($start_dir);
    rm_fr(".testlink");
    return $result;
}

sub have_library {
    my ($lib, $func, $header) = (@_, 'blank', 'blank');
    printf("checking for %s() in -l%s... ", $func, $lib) if $func ne 'blank';
    printf("looking for -l%s... ", $lib) if $func eq 'blank';
    $header = $lib if $header eq 'blank';

    my $result;
    # try to find a specific function in the library
    if ($func ne 'blank') {
        my $libs = $is_Win32 ? " $lib.lib  " : "-l$lib";

        if ($is_Win32) {
            $result = try_link(<<"SRC",undef );
#ifdef _CYGWIN
#include <windows.h>
#endif
#include <${header}.h>
blank() { return 0; }
int t() { ${func}(); return 0; }
SRC
            unless ($result) {
                $result = try_link(<<"SRC", undef);
#ifdef _CYGWIN
#include <windows.h>
#endif
#include <${header}.h>
blank() { return 0; }
int t() { void ((*p)()); p = (void ((*)()))${func}; return 0; }
SRC
            }

        } else {
            $result = try_link(<<"SRC", undef);
#include <${header}.h>
blank() { return 0; }
int t() { ${func}(); return 0; }
SRC
        }

    # no function was specified, so just try to load or link against the library
    } else {
        if($has_Win32) {
            my $driver_ok = Win32::LoadLibrary("${lib}.dll");
            $result = 1 and Win32::FreeLibrary($driver_ok) if $driver_ok;

        } else {
            $result = try_link(<<"SRC", undef);
#ifdef _CYGWIN
#include <windows.h>
#endif
#include <${header}.h>
blank() { return 0; }
SRC
        }
    }

    unless ($result) {
        print "no\n";
        return 0;
    }

    if ($func ne "main") {
        $options{DEFINE} .= uc(" -Dhave_$func");
    }

    print "yes\n";
    return 1;
}


sub have_functions {
    my @funcs = ();
    print "detecting available functions... ";

    my @paths = DynaLoader::dl_findfile(qw(-lpcap));
    my $libref = DynaLoader::dl_load_file($paths[0]);

    for my $func (@_) {
        my $symref = DynaLoader::dl_find_symbol($libref, $func);
        push @funcs, $func if defined $symref
    }

    print "ok\n";
    return @funcs
}

sub cpp_defines {
    return join '', sort map { " -DHAVE_\U$_" } @_
}


sub find_functions {
    # these functions are present since the very beginning so there's no need
    # to search for them
    my %old_func = map { $_ => 1 } qw(
        pcap_lookupdev  pcap_lookupnet  pcap_open_live  pcap_open_offline
        pcap_close      pcap_loop       pcap_dispatch   pcap_next   pcap_stats
        pcap_compile    pcap_freecode   pcap_setfilter  pcap_datalink
        pcap_dump_open  pcap_dump_close pcap_dump       pcap_file   pcap_fileno
        pcap_snapshot   pcap_is_swapped pcap_major_version      pcap_minor_version
        pcap_perror     pcap_strerror   pcap_geterr
    );

    my @funcs = ();

    # search for the functions list in the documentation
    open(PM, '<Pcap.pm') or die "fatal: can't read 'Pcap.pm': $!\n";
    while (my $line = <PM>) {
        next unless $line =~ /^=item +B<(pcap_\w+)\(.*\)>$/;
        push @funcs, $1 unless $old_func{$1};
    }

    close(PM);

    return @funcs
}

