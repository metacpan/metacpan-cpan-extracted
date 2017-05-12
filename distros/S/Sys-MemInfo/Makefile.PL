use 5.006;
use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use File::Copy 'copy';

my $libs = '';
my $define = '';

for ($^O) {
  if (/svr/) {
    copy ('arch/sco.xs', 'MemInfo.xs');
    print "Sys::MemInfo for UnixWare\n";
  } elsif (/aix/) {
    copy ('arch/aix.xs', 'MemInfo.xs');
    $libs = '-lperfstat';
    print "Sys::MemInfo for AIX\n";
  } elsif (/linux/ or /cygwin/) {
    copy ('arch/linux.xs', 'MemInfo.xs');
    my $kver = `uname -r`;
    die "Error extracting kernel version.\n" unless ($kver =~ /^(\d+)\.(\d+)(?:\.(\d+))?/);
    if ($1<=2 && ($2<3 || ($2==3 && $3<17))) {
      $define = '-DOLDKERNEL';
      print "Sys::MemInfo for Linux 2.3.16 and lower\n";
    } else {
      print "Sys::MemInfo for Linux 2.3.17 and higher\n";
    }
  } elsif (/solaris/) {
    copy ('arch/solaris.xs', 'MemInfo.xs');
    print "Sys::MemInfo for Solaris\n";
  } elsif (/freebsd/) {
    copy ('arch/freebsd.xs', 'MemInfo.xs');
    $kver = `uname -r`;
    die "Error extracting kernel version.\n" unless ($kver =~ /^(\d+)\./);
    if ($1>=5) {
      $define = '-DFREEBSD5';
      print "Sys::MemInfo for FreeBSD 5 and higher\n";
    } else {
      print "Sys::MemInfo for FreeBSD 4 and lower\n";
    }
  } elsif (/bsd/) {
    copy ('arch/bsd.xs', 'MemInfo.xs');
    if (/netbsd/) {
      $define = '-DNETBSD';
      print "Sys::MemInfo for NetBSD\n";
    } else {
      print "Sys::MemInfo for *BSD\n";
    }
  } elsif (/hpux/) {
    copy ('arch/hpux.xs', 'MemInfo.xs');
    $define ='-D_XOPEN_SOURCE_EXTENDED';
    print "Sys::MemInfo for HPUX\n";
  } elsif (/dec_osf/) {
    copy ('arch/tru64.xs', 'MemInfo.xs');
    $libs='-lmach';
    print "Sys::MemInfo for Tru64\n";
  } elsif (/MSWin32/) {
    copy('arch/win32.xs', 'MemInfo.xs');
    require Win32;	
    my (undef, $version)= Win32::GetOSVersion() ;
    if ($version && 5 <= $version) {
      print "Sys::MemInfo for Windows 200X/XP/Vista and higher\n";
    } else {
      print "Sys::MemInfo for Windows 9X/ME/NT\n";
      $define='-DOLDWIN';
    }  
  } elsif (/irix/) {
    copy('arch/irix.xs', 'MemInfo.xs');
    print "Sys::MemInfo for Irix\n";
  } elsif (/darwin/) {
    copy('arch/darwin.xs', 'MemInfo.xs');
    print "Sys::MemInfo for MacOS X Darwin\n";
  } else {
    die "unsupported OS: $_\n";
  }
}


WriteMakefile(
  'NAME'         => 'Sys::MemInfo',
  'VERSION_FROM' => 'MemInfo.pm', # finds $VERSION
  'DEFINE'       => $define,
  'NORECURS'     => 1,
  'XSOPT'        => '-noprototypes',
  'XS'           => { 'MemInfo.xs'  => 'MemInfo.c', },
  clean => { 'FILES' => 'MemInfo.xs', },
  'LIBS'         => $libs,

  ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM => 'MemInfo.pm', # retrieve abstract from module
    'AUTHOR'       => 'Sylvain CRESTO <scresto@gmail.com>') : ()),
);

# vim:et:ts=2:sts=2:sw=2
