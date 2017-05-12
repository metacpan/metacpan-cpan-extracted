#!/usr/bin/perl -w

#
# This Makefile.PL is an interface to ./configure intended to be used 
# by automatic CPAN builds. It just checks that some needed environment
# variables are set and eventually tries to guess their value... 
#
# You should use it instead of the ./configure program ;
# it accepts the same options.
#

use strict;

my $libname = "libqt-mt.so";
my @prefix = ('/usr', '/usr/local');

my $res="";
my %p;
my @alt;

exec "./configure --help" if grep /^-?-h(elp)?$/, @ARGV;

unless ($ENV{'QTDIR'} or grep /--with-qt-dir/, @ARGV)
{
  print "\n!!!!!!!!!!!! WARNING !!!!!!!!!!!!\n".
        " Your QTDIR environment variable is not set and you\n".
        "did not use the '--with-qt-dir=' commandline option.\n".
        "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n";
  print "Nevermind, I'll try to guess Qt's location.\n";
  sleep(6);
  for(@prefix)
  {
    my $stdpath = $_."/lib/qt3/lib";
    if(-s $stdpath."/$libname") 
    { 
      push @alt, glob($stdpath."/$libname*");
      print "Found what looks like a Qt-3 tree in $_/lib/qt3\n";
      sleep(1);
    }
  }
  
  unless (@alt)
  {  
    @alt=`locate $libname 2>/dev/null`;

    if(!check_exit_status($?) || !@alt)
    {
      print "mmh... locate did not help. We'll try a find then.\n";
      sleep(2);
    
      print "Scanning local file system (ctrl-c to abort)...\n";
      @alt=`find / -name "$libname*" 2>/dev/null`;    
    }
  }

  if(!check_exit_status($?) || !@alt)
  {
    print "Still no luck... I'll give up and let ./configure work it out\n";
  }
  elsif(@alt>1)
  {
    print "We have several answers. I'll try to discriminate a bit...\n";
    sleep(3);
    for(@alt) { /(.*)\/lib\// and $p{$1}++ }
    if(keys %p == 1)
    {
      $res = each %p;
    }
    else
    {
      my ($ver,$tmp)=(0,0);
      for(@alt)
      { 
        /$libname(?:\.(\d+))?(?:\.(\d+))?(?:\.(\d+))?$/o;
        $tmp = (($1?$1:0)*100)+(($2?$2:0)*10)+($3?$3:0);
        if($tmp>=$ver)
        {
          $ver = $tmp;
          $res = (/(.*)\/lib\//)[0]
        }
      }
      $res = each %p if keys %p ==1;
    }
    print $res?"OK. We can try --with-qt-dir=$res.\n":"No, that's too fuzzy. I'll give up and let ./configure decide.\n";  
  }
  else
  {
    ($res=$alt[0])=~s|(.*)/lib/.*|$1|;
    print "Fine. We'll try with --with-qt-dir=$res.\n";
  }  
  sleep(3);
}

unshift(@ARGV, "--with-qt-dir=$res") if $res;

unless ($ENV{'KDEDIR'} or grep /--prefix/, @ARGV)
{
  print "\n!!!!!!!!!!!! WARNING !!!!!!!!!!!!\n".
        " Your KDEDIR environment variable is not set and you\n".
        "did not use the '--prefix=' commandline option.\n";
  print "KDE-3 isn't required at all. However, if it's installed on your system,\n".
        "it is much better to specify it's location since PerlQt uses (or build, if\n".
        "it can't find it) a KDE library named smokeqt.\n";
  print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n";
  sleep(5);
}

print "\nNow starting ./configure ...\n\n";

exec join " ", "./configure", @ARGV;

#--------------------------------------------------------------#

sub check_exit_status
{
        my $a = 0xFFFF & shift;
        if( !$a )
        {
                return 1;
        }
        elsif( $a == 0xFF00 )
        {
                #die "\nSystem call failed: $!\n";
        }
        elsif( $a > 0x80 )
        {
                # non-zero status.
        }
        else
        {
                if( $a & 0x80 )
                {
                       #die "\nProgram coredumped with signal ". ($a & ~0x80);
                }
                die "\nProgram interrupted by signal $a\n";
        }
        return 0;
}

