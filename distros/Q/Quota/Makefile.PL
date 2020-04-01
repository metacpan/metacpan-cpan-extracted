#!/usr/local/bin/perl

# You shouldn't need to change anything here.
# All configuration is done in the hints/ directory.
#-----------------------------------------------------------------------------#
#
# Automagically choose the right configuration
#
chop($os = `uname -rs 2>/dev/null`);
if   ($os =~ /^SunOS 4\.1/){ $config='sunos_4_1.h'; }
elsif($os =~ /^SunOS 5/)   { $config='solaris_2.h'; }
elsif($os =~ /^HP-UX (A\.09|B\.10|[BC]\.11)/) { $config='hpux.h'; }
elsif($os =~ /^IRIX 5/)    { $config='irix_5.h'; }
elsif($os =~ /^IRIX\d* 6/) { $config='irix_6.h'; }
elsif($os =~ /^OSF1/)      { $config='dec_osf.h'; }
elsif($os =~ /^Linux/)     { $config='linux.h'; $picobj='linuxapi.o'; }
elsif($os =~ /^AIX/)       { $config='aix_4_1.h'; }
elsif($os =~ /^BSD\/OS 2/ ||
      $os =~ /^Darwin/    ||
      $os =~ /^FreeBSD/   ||
      $os =~ /^NetBSD/    ||
      $os =~ /^OpenBSD/)   { $config='bsd.h'; }

if (defined($config)) {
  print "Using hints/$config for myconfig.h\n";
  if (-e "myconfig.h" && (!(-l "myconfig.h") || (readlink("myconfig.h") ne "hints/$config"))) {
     die "\nFATAL: myconfig.h already exists.\n\n" .
         "You need to do a `make clean' before you configure for a new platform.\n".
	 "If that doesn't help, remove myconfig.h manually.\n";
  }
}
else {
  warn "WARNING: No appropriate hints found for this OS: '$os - see INSTALL'\n";
}

my $extralibs = "";

# check whether the Andrew File System (AFS) is installed and running

if ( -d "/afs" ) {
  my $afs = `df /afs 2>/dev/null`;
  if ($afs =~ /\nAFS|\(AFS/) {
    $hasafs = '-DAFSQUOTA';
    $AFSHOME = -d "/usr/afsws" ? "/usr/afsws" : "/usr";
    $extrainc = "-I$AFSHOME/include -I$AFSHOME/include/afs";
    $extralibs .= " -L$AFSHOME/lib -L$AFSHOME/lib/afs -lsys -lrx -lrxkad -llwp";
    $afsquota = "afsquota.o";
  }
}

# check to see if we have a kernel module for the Veritas file system
if ( $os =~ /^SunOS/ ) {
   if ( -f '/usr/include/sys/fs/vx_quota.h' ) {
     $hasvxfs = '-DSOLARIS_VXFS';
     $extraobj = "$extraobj vxquotactl.o";
     print "Configured with the VERITAS File System on Solaris\n";
   }
   # no warning because newer versions of Solaris have internal VxFS support
   # else {
   #   print "Configured without VxFS support\n";
   # }
}

# check whether we are using the NetBSD quota library
if ( ($os =~ /^NetBSD (\d+)\.(\d+)\.(\d+)/) &&
     (($1 >= 6) || (($1 == 5) && ($2 == 99) && ($3 >= 59)) )) {
  $extralibs .= " -lquota";
}

# check whether RPCSVC is included within libc
# - SUN RPC/XDR support was split off from glibc, see:
#   https://lists.fedoraproject.org/archives/list/devel@lists.fedoraproject.org/thread/F2NRCEXDDUF6WWNPSOMXRJS6BPMTEEVJ/
# - in RHEL apparently the rpc/rpc.h header was moved too;
#   Debian has libtirpc, but headers and implementation are still in glibc too
if (($os =~ /^Linux/) && (-d '/usr/include/tirpc')) {
  print "Configured to use tirpc library instead of rpcsvc\n";
  $extrainc = "-I/usr/include/tirpc";
  $rpclibs .= "-ltirpc";
}
else {
  if (($os =~ /^Linux/) && (!-e '/usr/include/rpc/rpc.h')) {
    print "WARNING: Header file /usr/include/rpc/rpc.h not present on this system.\n" .
          "         Likely compilation will fail. Recommend to either install package\n" .
          "         \"libtirpc-dev\", or disable RPC (network file system) support by\n" .
          "         adding the following switch to myconfig.h:\n" .
          "         #define NO_RPC\n";
  }
  $rpclibs .= "-lrpcsvc";
}

#-----------------------------------------------------------------------------#

use ExtUtils::MakeMaker;

&WriteMakefile('NAME'         => 'Quota',
               'OBJECT'       => '$(BASEEXT)$(OBJ_EXT) stdio_wrap.o '.
                                 "$afsquota $picobj $extraobj ". $hint{'OBJ'},
               'INC'          => $extrainc .' '. $hint{'INC'},
               'DEFINE'       => "$hasafs $hasvxfs",
               'LIBS'         => [ "$rpclibs $extralibs" ],
               'H'            => [ 'myconfig.h' ],
               'VERSION_FROM' => 'Quota.pm',
               'clean'        => { FILES => 'myconfig.h' },
);


#
#  Add rules for hints (myconfig.h)
#  and extra objects that need special compiler arguments
#

sub MY::postamble
{
    my $ret = '';
    my $extrac;

    if(!defined $config) {
      $ret .= '
myconfig.h:
	@echo "You need to make a myconfig.h.  See the file INSTALL.";
	@false
'
    }
    else {
      $ret .= "
myconfig.h:
	rm -f myconfig.h
	ln -s hints/$config myconfig.h
"
    }

    # objects that must not be compiled with the CCCDL arguments

    if (defined $extraobj) {
        ($extrac = $extraobj) =~ s/\.o(\s+|$)/.c/g;
        $ret .= "\n$extraobj :\n\t".
                '$(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) '."$extrac\n\n";
    }

    # extract objects from a library to link them in statically
    # for lame OSes that have problems with LD_PATH recording in DLOs

    if (defined $hint{'ARXLIBOBJ'}) {
        $hint{'ARXLIBOBJ'} =~ /\s+/;
        $ret .= "\n$' :\n\t\$(AR) x " . $hint{'ARXLIBOBJ'} ."\n\n";
    }

    $ret;
}
