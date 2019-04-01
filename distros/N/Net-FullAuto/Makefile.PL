### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2019  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or
#    modify it under the terms of the GNU Affero General Public License
#    as published by the Free Software Foundation, either version 3 of
#    the License, or any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty
#    of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public
#    License along with this program.  If not, see:
#    <http://www.gnu.org/licenses/agpl.html>.
#
#######################################################################

################################################################
#
#  Makefile.PL for Net::FullAuto
#
################################################################


our $VERSION='1.0000469';


if ($ENV{'AUTOMATED_TESTING'}) {
#if (1) {

   my $message=<<'END';

      DEAR CPAN TESTERS:

      Net::FullAuto has over 100 CPAN module dependencies. 

      One of the major goals of Net::FullAuto is easy and reliable
      installation on all Linux/Unix and Windows/Cygwin hosts.

      If it was possible to rely on all CPAN authors whose modules were
      found helpful to the Net::FullAuto project, to write installers
      that always worked in all these environments, never asked for input
      confusing to users without a lot of Perl familiarity, that worked with
      older versions of CPAN, (or newer ones) etc., then this Makefile.PL
      would be a lot simpler.

      Furthermore, with the advent of the public cloud, users are
      increasingly using machine images with inconsistent Perl installations.
      Many of the these users are not Perl experts, and would not be able
      to successfully remedy these issues on their own.
 
      Because of the large number of dependencies, and the almost impossible
      task of keeping current with them all under default CPAN configurations
      and rules, a decision was made to go with continuous integration of
      updated modules with every Net::FullAuto install.

      That means this Makefile.PL will update dependant modules, and remove
      older versions of modules installed in different locations that
      cause them to load ahead of the desired one.

      Users are warned up front of this behavior, and have a 2 minute window
      to abort installation.

      This author is fully aware of the "local::lib" approach to coping with
      some of these issues, but local::lib solves the problem only for a
      specific user, and not at the system level.

      With the advent of machine images, "whole systems" are now spun up in
      seconds, and just as quickly discarded. Users are going to have less
      and less patience for software that does not install and work almost as
      fast and reliably.

      Continuous integration is the trend, and Net::FullAuto is an early
      adopter. However, it has caused problems for CPAN testers, which is
      why automated testing is disabled - and is likely to remain so for the
      foreseeable future.

      Of course you are welcome and invited to test or use Net::FullAuto at
      any time, - simply comment out the AUTOMATED_TESTING environment
      variable conditional at the top of Makefile.PL and replace it with:
    
         if (1) {

      To avoid issues - I suggest testing on a virgin virtual machine.
      Net::FullAuto installs on an Amazon Free Tier micro server without
      issue. Just launch one up, and install cpan with this command:

      sudo yum -y install cpan  (on FreeBSD: 'su' then 'pkg_add -r perl')
                                (See instructions at line 1529 for openSuSe)

      run cpan and at the cpan command prompt type "install Net::FullAuto".

      Be sure $ENV{'AUTOMATED_TESTING'}==0.

      Net::FullAuto will install successfully on any Linux flavor or FreeBSD
      server in Amazon EC2. It will also install with Cygwin on Windows.

      I am willing and eager to work with anyone who is curious or
      interested in the Net::FullAuto project.

      Thank you,
      Brian Kelly
      March 27, 2016

      Brian.Kelly@FullAuto.com

END

   print $message; 
   exit 0;

}

BEGIN { # FullAuto© MICROSOFT WINDOWS INSTALLER

   # All the code in this BEGIN block is used exclusively by the
   # FullAuto MS Windows Installer. You can download the Windows
   # Installer at:
   #
   #    https://sourceforge.net/projects/fullauto/files/latest/download
   #
   #       or
   #
   #    http://www.FullAuto.com
   #
   # The Windows Installer is written entirely with Perl and the
   # PAR Packager. If is a fully self contained .exe file and contains
   # everything needed to automatically install stand alone FullAuto©
   # or FullAuto© and the FullAuto© REST Web API which includes fully
   # automated TURNKEY installations of Cygwin, Catalyst and ZeroMQ.
   # Cygwin is a dependency for both FullAuto© and the FullAuto© Web
   # API on MS Windows and is installed automatically by the FullAuto©
   # Windows Installer.

   if (exists $ENV{PAR_TEMP} && $^O ne 'cygwin') {
      chdir "$ENV{PAR_TEMP}\\\\inc\\\\lib";
      my $partmp=`set`;
      my $partemp=$partmp;
      my $windir=$partmp;
      if ($partmp=~s/^.*PAR_TEMP=(.*?)\n.*$/$1/s) {
         $windir=~s/^.*windir=(.*?)\n.*$/$1/s;
         $windir=~s/\\/\\\\/g;
         $partmp=~s/\\/\\\\/g;
         my $cpancfg="$partmp\\\\inc\\\\lib\\\\CPAN\\\\Config.pm";
         my $ch=$partmp."\\\\inc\\\\cpan";
         my $cfg=`cmd /c type $cpancfg`;
         $cfg=~s/^(.*cpan_home[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$ch$2/s;
         my $ksw='keep_source_where';
         my $chi=$ch."\\\\sources";
         $cfg=~s/^(.*$ksw[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $chi=$ch."\\\\prefs";
         $cfg=~s/^(.*prefs_dir[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $chi=$ch."\\\\build";
         $cfg=~s/^(.*build_dir[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $chi=$ch."\\\\histfile";
         $cfg=~s/^(.*histfile[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $cfg=~s/^(.*use_sqlite[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/${1}0$2/s;
         $chi=$partmp."\\\\inc\\\\tools\\\\tar.exe";
         $cfg=~s/^(.*tar[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $chi=$partmp."\\\\inc\\\\tools\\\\wget.exe";
         $cfg=~s/^(.*wget[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $chi=$partmp."\\\\inc\\\\tools\\\\dmake.exe";
         $cfg=~s/^(.*make[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $chi=$partmp."\\\\inc\\\\tools\\\\less.exe";
         $cfg=~s/^(.*pager[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $chi=$partmp."\\\\inc\\\\tools\\\\unzip.exe";
         $cfg=~s/^(.*unzip[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $chi=$partmp."\\\\inc\\\\tools\\\\bzip2.exe";
         $cfg=~s/^(.*bzip2[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $chi=$partmp."\\\\inc\\\\tools\\\\patch.exe";
         $cfg=~s/^(.*patch[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $chi=$partmp."\\\\inc\\\\tools\\\\gzip.exe";
         $cfg=~s/^(.*gzip[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$chi$2/s;
         $cfg=~s/^(.*gpg[']?\s*[=][>]\s*q[[])[^]]+([]].*)$/$1$2/s;
         open(CF,">$cpancfg");
         print CF $cfg;
         close CF;
      }
   }
   if (exists $ENV{PAR_TEMP} && $^O eq 'cygwin') {
      # This block removes the PAR lib path from @INC which
      # breaks the installation once Cygwin is available.
      my $cygpar=`/usr/bin/cygpath -u $ENV{PAR_TEMP} 2>&1`;
      foreach my $lib (@INC) {
         next if $lib eq $cygpar;
         push @TMPINC,$lib;
      }
      @INC=@TMPINC;
   }

};

use Config;
use CPAN;
unshift @ExtUtils::MakeMaker::Overridable, 'pm_to_blib'; # this enables
         # pm_to_blib to be overwritten in Makefile rather than ignored
*{MyClass::_using_sudo} = sub { return 1 }; # Override default local::lib
                                            # Net::FullAuto is currently
                                            # not compatible with local::lib
                                            # When CPAN is found in an
                                            # unconfigured condition,
                                            # "sudo" instead of local::lib.
$ENV{'CYGWIN'}='nodosfilewarning' if $^O eq 'cygwin';
use lib '.';
use subs qw/version name sign author license perl_version/;
use inc::Module::Install;

use if (($^O eq 'cygwin' && eval { 
   local $SIG{__DIE__};require 'Win32::RunAsAdmin' })
   || $^O eq 'MSWin32' || $^O eq 'MSWin64'),
   'Win32::RunAsAdmin'; # Used to check Admin Priviliges on MS Windows

if ((($^O eq 'cygwin' && eval {
      local $SIG{__DIE__};require 'Win32::RunAsAdmin' })
      || $^O eq 'MSWin32' || $^O eq 'MSWin64') &&
      not Win32::RunAsAdmin::check()) {
   my $name=substr($0,(rindex $0,'\\')+1);
   $name=$ENV{SESSIONNAME} unless exists $ENV{PAR_TEMP};
   my $message=<<END;


   FATAL ERROR! - Windows Administrator privileges are needed in
                  order to install FullAuto or OpenSSH.
  
   If you have Administrator Rights, be sure to Right Click on the

      $name

   icon and select  -->  "Run as administrator"

   or, contact your Windows System Administrator to resolve.


END
   print $message;
   if (exists $ENV{PAR_TEMP}) {
      print "   PRESS ANY KEY to Exit Setup\n\n";
      <STDIN>;
   } exit 1;

}

# ASCII BANNER Courtesy of:  http://www.network-science.de/ascii/
# When FullAuto is installed, run:  fa --figlet  to view multiple fonts.

my $c=($^O ne 'MSWin32' && $^O ne 'MSWin64')?'©':'(C)';
my $fa_banner=<<END;




    __       __)
   (, )  |  /      /)
      | /| /   _  // _  ______    _    _/_ ___
      |/ |/  _(/_(/_(__(_) // (__(/_   (__(_)
      /  |



           _   _      _         _____      _ _    _         _
          | \\ | | ___| |_      |  ___|   _| | |  / \\  _   _| |_  |  
          |  \\| |/ _ \\ __| o o | |_ | | | | | | / _ \\| | | | __/ | \\
          | |\\  |  __/ |_  o o |  _|| |_| | | |/ ___ \\ |_| | ||     |
          |_| \\_|\\___|\\__|     |_|   \\__,_|_|_/_/   \\_\\__,_|\\__\\___/ $c 



   Copyright $c 2000-2019  Brian M. Kelly  Brian.Kelly\@FullAuto.com


END

#####################################################################
# The following code is used ONLY with Amazon EC2 images. Most of
# the images found will not install CPAN modules without some
# preparation, such asinstalling CPAN itself from repositories.
#
# BEGIN Amazon EC2 specific code

our %amazon=();
if ($ARGV[0]=~/\.pem/) {
   push @{$amazon{argv}},$ARGV[0];
}
our $system_type='';
# Bullet Proof Test for AWS EC2
# wget --tries=1 --timeout=5 -qO- http://169.254.169.254/latest/dynamic/instance-identity/document 2>&1
my $aws=`wget --tries=1 --timeout=5 -qO- http://169.254.169.254/latest/dynamic/instance-identity/document 2>&1`;
$aws=(-1<index $aws,'signature')?1:0;
if ($^O eq 'linux' || $^O eq 'freebsd') {
   if ((-e "/etc/system-release-cpe") &&
         ((-1<index `cat /etc/system-release-cpe`,'amazon:linux') ||
         (-1<index `cat /etc/system-release-cpe`,'amazon_linux'))) {

      # Manual Setup Amazon AMI host before CPAN:
      #
      # sudo yum -y install cpan

      $amazon{'amazon_linux'}='';
      $system_type='amazon_linux';
   } elsif ((-e "/etc/os-release") &&
         (-1<index `cat /etc/os-release`,'ubuntu')) {
      $amazon{'ubuntu'}='' if $aws;
      $system_type='ubuntu';
   } elsif ($^O eq 'freebsd') {

      # Manual Setup FreeBSD host before CPAN:
      #
      # su
      # pkg_add -r perl

      $amazon{'freebsd'}='' if $aws;
      $system_type='freebsd';
   } elsif (-e "/etc/SuSE-release") {
      $amazon{'suse'}='' if $aws;
      $system_type='suse';
   } elsif ((-e "/etc/system-release-cpe") &&
         (-1<index `cat /etc/system-release-cpe`,
         'fedoraproject')) {
      $amazon{'fedora'}='' if $aws;
      $system_type='fedora';
   } elsif ((-e "/etc/system-release-cpe") &&
         (-1<index `cat /etc/system-release-cpe`,
         'redhat:enterprise_linux')) {

      # Manual Setup Redhat host before CPAN:
      #
      # sudo yum -y install cpan

      $amazon{'rhel'}='' if $aws;
      $system_type='rhel';
   } elsif ((-e "/etc/system-release-cpe") &&
         (-1<index `cat /etc/system-release-cpe`,
         'centos:')) {

      # Manual Setup CentOS host before CPAN:
      #
      # sudo yum -y groupinstall "Development tools"
      # sudo yum -y install cpan 

      $amazon{'centos'}='' if $aws;
      $system_type='centos';
   } elsif (-e "/etc/gentoo-release") {

      # Manual Setup CentOS host before CPAN:
      #

      $amazon{'gentoo'}='' if $aws;
      $system_type='gentoo';
   }
} else { $system_type=$^O }

## END Amazon EC2 specific code.

sub msw64bit {
   return 0 if $^O ne 'cygwin' && $^O ne 'MSWin32' && $^O ne 'MSWin64';
   my $bitout=`wmic os get osarchitecture`;
   return 1 if -1<index $bitout,'64';
   return 0;
} 

sub check_cygserver {

   my $check_for_orphaned_cygserver_service=`sc qc cygserver 2>&1`;
   unless (-1<index $check_for_orphaned_cygserver_service,'does not') {
      my $cygpath=~s/^.*H_NAME\s+:\s+(.*exe).*$/$1/s;
      $cygpath=~s/\\/\//g;
      unless (-e $cygpath) {
         # cygrunsrv does not exist - let's see if its running?
         my $chkrun=`sc query cygserver 2>&1`;
         if (-1<index $chkrun,'RUNNING') {
            # Its running - let's stop it
            my $stopout=`net stop cygserver 2>&1`;
            unless (-1<index $stopout,'stopped suc') {
               print "FATAL ERROR! - cannot stop cygserver: $stopout\n";
               exit 1;
            }
         }
         # Now let's delete cygserver
         my $sc_out=`sc delete cygserver 2>&1`;
         unless (-1<$sc_out,'SUCCESS') {
            print "FATAL ERROR! - cannot delete cygserver: $sc_out\n";
            exit 1;
         }
      }
   } return 0;

}

sub get_cygwin_location {
   my $cygwin_query=
         `REG QUERY HKEY_LOCAL_MACHINE\\SOFTWARE\\Cygwin\\setup 2>&1`;
   my $showcq=$cygwin_query;
   my $sep='\\';
   if ((-1<index $showcq,'unable to find') && msw64bit()) {
      $cygwin_query="$ENV{windir}\\sysnative\\cmd.exe /c ".
         "REG QUERY HKEY_LOCAL_MACHINE\\SOFTWARE\\Cygwin\\setup 2>&1";
      $showcq=$cygwin_query=`$cygwin_query`;
   } elsif ((-1<index $showcq,'Invalid key name') ||
         (-1<index $showcq,'cannot find the path') ||
         (-1<index $showcq,'unable to find')) {
      $cygwin_query=
         `REG QUERY HKEY_LOCAL_MACHINE\\\\SOFTWARE\\\\Cygwin 2>&1`;
      $showcq=$cygwin_query;
      $sep='\\\\';
   }
   $showcq=~s/^/   /mg;chomp $showcq;
   my $cygwin_query_success=0;
   if (-1<index $cygwin_query,'REG_SZ') {
      $cygwin_query_success=1;
   } else {
      my $rcmd="REG QUERY HKEY_LOCAL_MACHINE${sep}SOFTWARE$sep".
               "Wow6432Node${sep}Cygwin${sep}setup 2>&1";
      $cygwin_query=`$rcmd`;
      $showcq=$cygwin_query;
      $showcq=~s/^/   /mg;chomp $showcq;
      if (-1<index $cygwin_query,'REG_SZ') {
         $cygwin_query_success=1;
      }
   }
   if ($cygwin_query_success) {
      #print "\n   REG QUERY RESULT:\n\n   $showcq";
      $cygwin_query=~s/^.*REG_SZ\s+(.*)\s*$/$1/s;
      $cygwin_query=~s/^\s*//s;
      $cygwin_query=~s/\s*$//s;
      unless (-W $cygwin_query) {
         unless (-d $cygwin_query) {
            # The cygwin directory indicated in the Registry does not
            # exist - let's delete the Registry entry
            if (-1<$cygwin_query,'Wow6432') {
               my $rcmd="REG DELETE HKEY_LOCAL_MACHINE${sep}SOFTWARE${sep}".
                        "Wow6432Node${sep}Cygwin /f 2>&1";
               my $regout=`$rcmd`;
               return 0;
            } else {
               my $rcmd='REG DELETE HKEY_LOCAL_MACHINE'.
                        "${sep}SOFTWARE${sep}Cygwin /f 2>&1";
               my $regout=`$rcmd`;
               return 0;
            }
         }
         if (-1<index $0,'Setup-FullAuto') {
            my $name=substr($0,(rindex $0,'\\'));
            print "\n\n".
               "   FATAL ERROR! - Write Access to $cygwin_query\n".
               "   is needed in order to install FullAuto or OpenSSH.\n\n".
               "   If you have Administrator Rights, be sure to Right\n".
               "   Click on the $name\n   icon and select ".
               "\"Run as administrator\"\n\n".
               "   Or, contact your Windows System Administrator\n".
               "   to resolve.\n\n   PRESS ANY KEY to Exit Setup\n\n";
         } else {
            print "\n\n".
               "   FATAL ERROR! - Write Access to $cygwin_query\n".
               "   is needed in order to install FullAuto or OpenSSH.\n\n".
               "   Please contact your Windows System Administrator\n".
               "   to resolve.\n\n   PRESS ANY KEY to Exit Setup\n\n";
         }
         <STDIN>;
         exit 1;
      }
      my $getver='';
      if ($^O eq 'cygwin') {
         $getver='cygcheck -c cygwin 2>&1';
      } else {
         $getver='SET CYGWIN=nodosfilewarning & '.
             "cmd /c $cygwin_query${sep}bin${sep}bash -lc ".
             '"cygcheck -c cygwin" 2>&1';
      }
      my $cygver=`$getver`;
      if ($cygver=~/(1.7.11-1)/) {
         print "\n\n   FATAL ERROR! - The current Cygwin version: $1\n".
               "   (Base Cygwin cygwin1.dll) is incompatible with\n".
               "   FullAuto. Please update to either a newer or older\n".
               "   version of Base Cygwin before again attempting to\n".
               "   to install FullAuto.\n\n".
               "   You may need to contact your Windows System\n".
               "   Administrator to resolve.\n\n".
               "   PRESS ANY KEY to Exit Setup\n\n";
         <STDIN>;
         exit 1;
      }
      if (-e "$cygwin_query/bin/bash.exe") {
         my $getid='';
         if ($^O eq 'cygwin') {
            $getid='id 2>&1';
         } else {
            $getid='SET CYGWIN=nodosfilewarning & '.
                "cmd /c $cygwin_query${sep}bin${sep}bash -lc ".
                '"id"';
         }
         my $groups=`$getid`;
         my $adm_gr=`net localgroup Administrators`;
         $adm_gr=~s/^.*---\s*(.*)\s*The command.*$/$1/s;
         my @adm_gr=split /\n/, $adm_gr;
         my $admin_flag=0;
         foreach my $id (@adm_gr) {
            chomp($id);
            $id=~s/^.*\\(.*)$/$1/;
            if (-1<index $groups,"($id)" ||
                  ($ENV{'USERNAME'} eq 'Administrator')) {
               $admin_flag=1;
               last;
            }
         }
         unless ($admin_flag) {
            my $message=<<END;

   FATAL ERROR! - The User $ENV{USERNAME} needs to
   be a member of the Administrator's group in order
   to install FullAuto or OpenSSH.

   Please contact your Windows System Administrator
   to resolve.

END
            print $message;
            if (exists $ENV{PAR_TEMP}) {
               print "   Press ANY key to exit.\n\n";<STDIN>;
            }
            exit 1;
         }
      }
      if ($_[0]) {
         my $getpath='';
         $cygwin_query=~s/\\/\\\\/g;
         if ($^O eq 'cygwin') {
            $getpath="/usr/bin/cygpath -u $cygwin_query 2>&1";
         } else {
            $getpath='SET CYGWIN=nodosfilewarning & '.
                "cmd /c $cygwin_query${sep}bin${sep}bash -lc ".
                "\"/usr/bin/cygpath -u $cygwin_query\" 2>&1";
         }
         $cygwin_query=`$getpath`;
         chomp $cygwin_query;
         return '' if $cygwin_query eq '/';
      }
      return $cygwin_query;
   } return 0
} 

our $tee='';our $log='';
$SIG{ INT } = sub{ eval { require Term::ReadKey };
                   unless ($@) { Term::ReadKey::ReadMode(0) };
                   print "\n";
                   <STDIN> if exists $ENV{PAR_TEMP};
                   exit 1};
$SIG{__DIE__} = sub{ eval { require Term::ReadKey };
                   unless ($@) { Term::ReadKey::ReadMode(0) };
                   print "\n";
                   print $tee "FATAL ERROR!: $_[0]\n" if $tee
                     && $_[0]!~/close_everything/;
                   print "FATAL ERROR!: $_[0]\n"
                     && $_[0]!~/close_everything/;
                   $tee->close() if $tee;
                   $log->close() if $log;
                   <STDIN> if exists $ENV{PAR_TEMP};
                   exit 1};

use Cwd qw/cwd/;
use File::stat;
{
   local $SIG{__DIE__}; # No sigdie handler
   
   # In keeping with the continuous integration approach, and since an
   # increasing number of hosts are machine images, CPAN configuration and
   # setup is automated to the greatest extent possible. Users are advised
   # to allow this only on hosts where this is not a sensitive issue.
 
   eval {
      if (!(-e "$ENV{HOME}/.cpan/CPAN/MyConfig.pm") && !old_cpan() && -e $^X) {
         my $run_cpan="echo y | $^X -e \"require CPAN;".
               'require CPAN::FirstTime;'.
               '*{CPAN::FirstTime::_using_sudo}'. # Override default local::lib
               '= sub { return 1 };'.             # Net::FullAuto is currently
                                                  # not compatible with
                                                  # local::lib. When CPAN is
                                                  # found in an unconfigured 
                                                  # condition, "sudo" instead
                                                  # of local::lib is chosen.
               "CPAN::FirstTime::init(\'$Config{privlib}\');\" 2>&1";
         fa_system($run_cpan);
      }
      CPAN::HandleConfig->load;
   };
   if ($@) {
      if ((-x "/usr/local/bin/perl") && ($^X ne "/usr/local/bin/perl")) {
         my $timeout=300;my $a='';
         my $toperror=$@;
         my $die='';
         eval {
            local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
            alarm $timeout;
            my $message=<<END;

   ERROR!:  $toperror

            It appears that the perl installation used to run
            Makefile.PL is an old system installation, and not
            the intended one.

            Another perl installation using /usr/local/bin/perl
            as the primary executable has been discovered.

            Would you like Makefile.PL to be run against that
            installation?

END

            my $fae="No   (FullAuto Setup will exit)";
            my $menu1 = [
                        $message,
                        [ "Yes", sub{ return 'Yes' } ],
                        [ $fae, sub{ return 'No' } ],
                        ];
            my $selection=&menu($menu1);
            exit 0 if $selection eq ']quit[';
            exit 0 if -1<index $selection, 'No   (';
            my $argvs=join " ", @ARGV;
            exec "/usr/local/bin/perl Makefile.PL $argvs";
            alarm 0;
         };
         fa_die("$@: $!\n") if $@;
      };
      fa_die("$@: $!\n");
   }
};
use POSIX qw/strftime/;
my $mycpantest=0; 
our $cwd=&cwd;
our $PARdir=$cwd;
our $domain_gr_flag=0;
my $exec_cnt=0;
foreach my $dir (@INC) {
   my $incdir=$dir;
   $mycpantest=1 if -e $incdir."/CPAN/MyConfig.pm";
}
use if (exists $ENV{PAR_TEMP}), 'IO::Tee';
if (exists $ENV{PAR_TEMP}) {
   chdir $ENV{PAR_TEMP};
   $log=IO::Handle->new();
   open($log,">>$ENV{PAR_TEMP}/inc/stdout.log");
   $log->autoflush(1);
   $tee=new IO::Tee(\*STDOUT,$log);
   $tee->autoflush(1);
   select $tee;
   $INC{'Module/Install.pm'}=$ENV{PAR_TEMP}.'/inc/inc/Module/Install.pm'
      if -e $ENV{PAR_TEMP}.'/inc/inc/Module/Install.pm';
   $PARdir=$ENV{PAR_TEMP};
}
unless (exists $ENV{FA_EDITOR} || grep { /Encrypted|SKIP/i } @ARGV) {
   print $fa_banner;
   sleep 2;
   unless (exists $ENV{PAR_TEMP} || keys %amazon) {
      my $message=<<END;
    ___                     _            _     _
   |_ _|_ __  _ __  ___ _ _| |_ __ _ _ _| |_  | | This message times out in
    | || '  \\| '_ \\/ _ \\ '_|  _/ _` | ' \\  _| |_| 2 minutes so the FullAuto
   |___|_|_|_| .__/\\___/_|  \\__\\__,_|_||_\\__| (_) install can continue.
             |_| 
                   The FullAuto install behaves differently than other CPAN
   module installations. Normally CPAN will NOT update a dependency module
   if it already exists on the system, even if it is an older version. CPAN
   will NOT remove the same module found in more than one location, even if
   the old one has precedence in \@INC (meaning it will always load the old
   one.) FullAuto does not work with "local::lib" - so this install **WILL**
   UPDATE ALL DEPENDENCIES (over 100 of them) and remove any duplicates. If
   this is not acceptable to you, then do not install FullAuto on this host,
   or in the default Perl location. Either use a host where FullAuto can do
   this, or create a 2nd Perl installation that FullAuto can "own".

   Do you wish to continue this install?
END
      my $timeout=120;
      my $fae="No   (FullAuto Setup will exit)";
      {
         local $SIG{__DIE__}; # No sigdie handler
         eval {
            local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
            alarm $timeout;
            my $menu1 = [
                        $message,
                        [ "Yes", sub{ return 'Yes' } ],
                        [ $fae, sub{ return 'No' } ], 
                        ];
            my $selection=&menu($menu1);
            exit 0 if $selection eq ']quit[';
            exit 0 if -1<index $selection, 'No';
            alarm 0;
         };
      } print "\n\n   FullAuto install continues . . .\n\n";
   }
} elsif (grep { /SKIP/i } @ARGV) {
   $exec_cnt=$ARGV[$#ARGV];
   $exec_cnt++;
   my $module_fail=$ARGV[$#ARGV-1];
   my $mod_info='';
   eval {
      local $SIG{__DIE__}; # No sigdie handler;
      require CPAN;
      {
         local *STDOUT;
         open(STDOUT, ">", \$mod_info);
         CPAN::Shell->m($module_fail);
      }
   };
   my $instfile='';
   ($instfile=$mod_info)=~s/^.*INST_FILE\s+([^\s]+).*$/$1/s;
   my $instver='';
   ($instver=$mod_info)=~s/^.*INST_VERSION\s+([^\s]+).*$/$1/s;
   my $cpanfil='';
   ($cpanfil=$mod_info)=~s/^.*CPAN_FILE\s+([^\s]+).*$/$1/s;
   my $cpanver='';
   ($cpanver=$mod_info)=~s/^.*CPAN_VERSION\s+([^\s]+).*$/$1/s;
   if ($exec_cnt==1 && $cpanver ne $instver) {
      # Amazon's AMI has Pod::Man installed in the vendor_perl
      # directory which has precedence over the system directory
      # this module actually belongs in. The only solution is to
      # delete it from the vendor_perl area before we attempt to
      # install Pod::Man. We are doing this ONLY on Amazaon AMI
      # systems currently.
      fa_system("sudo echo y | /bin/rm -rf \"$instfile\"");
   } elsif (2<$exec_cnt) {
      my $timeout=300;my $a='';
      {
         local $SIG{__DIE__}; # No sigdie handler
         eval {
            local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
            alarm $timeout;
            $mod_info=~s/^.*?(CPAN.*)$/$1/s;
            $mod_info=~s/^\s*/      /mg;
            my $message=<<END;

   FATAL ERROR!: The following Perl CPAN module could not be
                 installed on your system:

     $module_fail

     $mod_info

   The FullAuto installation will not succeed without this
   module installed and loaded.

   Please report any bugs and send any
   questions, thoughts or feedback to:

      Brian.Kelly\@FullAuto.com

END
            print $message;
            if (exists $ENV{PAR_TEMP}) {
               print "   Press ANY key to exit.\n\n";<STDIN>;
            }
            return;
         };
         alarm 0;
      };
      exit 1;
   }
}

if (-e "dependencies/CPAN/authors" &&
      !(grep {
      /(?:use[-_]?)?internet|online|connect_to_internet_ok/i } @ARGV)) {
   opendir(DH,"dependencies/CPAN/authors/id/F/FR/FREW") ||
      fa_die("Cannot open dir dependencies/CPAN/authors/id/F/FR/FREW: $1\n");
   my $filenames_not_trunced=0;my $got_sub=0;
   while (my $line=readdir(DH)) {
      $line=~tr/\0-\11\13-\37\177-\377//d; 
      chomp($line);
      if ($line=~/Sub-Exporter-Progressive-.*gz$/) {
         $filenames_not_trunced=1;
         last;
      }
      if (-1<index $line,'Sub-') {
         $got_sub=1;
      }
   }
   close DH;
   unless ($filenames_not_trunced) {
      if ($got_sub) {
         if ($^O eq 'solaris' && (-e '/usr/sfw/bin/gtar')) {
            my $message=<<END;

   FullAuto Setup ERROR!:  It appears that the solaris system tar
                           command was used to expand
                           Net-FullAuto-Complete-$VERSION.tar.gz,
                           which is a problem. The solaris tar utility
                           has a limit on the length of directory depth
                           and filename that is exceeded by some of the
                           dependencies bundled with FullAuto Setup.

                           Use the tar utility /usr/sfw/bin/gtar to
                           expand Net-FullAuto-Complete-$VERSION.tar.gz.

END
            print $message;exit 1;
         } else {
            my $message=<<END;

   FullAuto Setup ERROR!:  It appears that the tar command used to expand
                           Net-FullAuto-Complete-$VERSION.tar.gz,
                           has a problem. Some tar utilities have a limit
                           on the length of directory depth and filename
                           that is exceeded by some of the dependencies
                           bundled with FullAuto Setup.

                           Hint: Install and use GNU tar to untar (expand)
                                 Net-FullAuto-Complete-$VERSION.tar.gz.

END
            print $message;exit 1;
         }
      } else {
         my $message=<<END;

   FullAuto Setup ERROR!:  It appears that there are missing dependencies
                           in the dependencies/CPAN/authors folder of this
                           Net-FullAuto-Complete distribution.

END
         print $message;exit 1;
      }
   }
   my $loc="$cwd/dependencies/CPAN";
   $CPAN::Config->{keep_source_where}=$loc;
   $CPAN::Config->{connect_to_internet_ok}=1;
   $CPAN::Config->{index_expire}=1000;
}

use File::Path;

our $cygwin_root_dir=$cwd;

my @drive_options=();
my $perl_version=$^V;
$perl_version=~s/^v//;
if ($^O eq 'cygwin') {
   my $cygcheck=`/bin/cygcheck -c` || fa_die($!);
   my $uname=`/bin/uname` || fa_die($!);
   my $uname_all=`/bin/uname -a` || fa_die($!);
   $uname_all.=$uname;
   my %need_packages=();
   if ($uname_all=~/x86_64/) {
      foreach my $package ('gcc-core','gcc-g++','make','openssh','openssl',
                           'openssl-devel','perl','db','libdb-devel',
                           'ncurses','cron','inetutils','procps-ng','vim',
                           'unzip','libmpfr4','libcrypt-devel','nano',
                           'perl-libwww-perl','perl-LWP-Protocol-https',
                           'wget','git','figlet','autobuild','autoconf',
                           'automake','libtool','libxml2','libxml2-devel',
                           'pkg-config','libisl15',
                           #'pkg-config','libisl15','libcloog-isl4',
                           'sqlite3','rpm','cpio','curl') {
         unless (-1<index $cygcheck, "$package ") {
            $need_packages{$package}='';
         }
      }
   } else {
      foreach my $package ('gcc-core','gcc-g++','make','openssh','openssl',
                           'openssl-devel','perl','perl-Win32','db4.8',
                           'libdb4.8-devel','ncurses','cron','inetutils',
                           'procps','vim','unzip','libmpfr4','nano',
                           'wget','git','figlet') {
         unless (-1<index $cygcheck, "$package ") {
            $need_packages{$package}='';
         }
      }
   }
   if (keys %need_packages) {
      my $packs='';
      foreach my $pack (sort keys %need_packages) {
         $packs.="$pack ";
      }
      if ($packs) {
         my $message=<<END;

   FATAL ERROR!: The following Cygwin
                 packages are missing from
                 your installation:

   $packs

   Please report any bugs and send any
   questions, thoughts or feedback to:

      Brian.Kelly\@FullAuto.com

END
         print $message;
         if (exists $ENV{PAR_TEMP}) {
            print "   Press ANY key to exit.\n\n";<STDIN>;
         }
         exit 1;
      }
   }
   my @required_cygwin_services=();
   SC: foreach my $cnt (1..3) {
      my $services=`ps -e` || fa_die($!);
      foreach my $cygwin_service ('cygserver') {
         if ($cnt==3) {
            push @required_cygwin_services, $cygwin_service;
            last SC;
         } elsif (-1==index $services,$cygwin_service) {
            `net start cygserver`;
             sleep 2;
             next SC;
         } else { last SC }
      }
   } 
   if (-1<$#required_cygwin_services) {
      my $services='';
      foreach my $service (sort @required_cygwin_services) {
         $services.="      $service\n";
      }
      if ($services) {
         my $message=<<END;

   FATAL ERROR!: The following Cygwin services are not running on your system:

   $services

   The FullAuto installation will not succeed without these services installed
   and running.

   Please report any bugs and send any
   questions, thoughts or feedback to:

      Brian.Kelly\@FullAuto.com

END
         print $message;
         if (exists $ENV{PAR_TEMP}) {
            print "   Press ANY key to exit.\n\n";<STDIN>;
         }
         exit 1;
      }
   }
   if (!can_cc()) { # Can also borrow cc test from version module:
                    # version-0.9912
      if ($Config{cc} && $Config{cc}=~/gcc-4/) {
         `cd /usr/bin;ln -s gcc.exe gcc-4`;
         `cd /usr/bin;ln -s g++.exe g++-4;cd $cwd`;
      } else {
         my $stup='setup-x86.exe';
         $stup='setup-x86_64.exe' if $uname=~/WOW64/ || msw64bit();
         my $die=<<END;

      FATAL ERROR! : The Gnu C Compiler 'gcc': gcc-core
                     & gcc-g++ as provided by Cygwin
                     is required to install FullAuto
                     on Windows.

      ( Hint: Run Cygwin $stup and install 'gcc-core'
              and 'gcc-g++' under the Category 'Devel' ).

END
         fa_die($die);
      }
   }
} elsif ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
   unless ($ENV{PAR_TEMP}) {
      my $die=<<'END';

      FATAL ERROR! : Cygwin Linux Emulation Layer
                     is required to use FullAuto
                     on Windows - goto www.cygwin.com.

         Be sure to install the following programs in
         addition to the base package:

         inetutils and openssh [as provided by Cygwin]
         perl [as provided by Cygwin] (*NOT* CPAN)
         perl-Win32 [as provided by Cygwin] (*NOT* CPAN)
         ncurses, cron, and procps-ng [as provided by Cygwin]
         gcc-core and gcc-g++ [as provided by Cygwin]
         Oracle Berkeley DB [as provided by Cygwin or Oracle]

         **IMPORTANT** - the FullAuto install, either manual
         or via CPAN, must be run *inside* a Cygwin bash shell
         when installing FullAuto on Microsoft Windows.

END
      fa_die($die);
   }
   use if ($^O eq 'MSWin32' || $^O eq 'MSWin64'), "Win32::DriveInfo";
   use if ($^O eq 'MSWin32' || $^O eq 'MSWin64'), "Term::Menus";

   fa_license();

   my $cygwin_loc=get_cygwin_location();
   #$cygwin_loc=0;
   if ($cygwin_loc) {
      my $drv=substr($cygwin_loc,0,1);
      my $dt=Win32::DriveInfo::DriveType($drv);
      my $FileSystemName=(Win32::DriveInfo::VolumeInfo($drv))[3];
      my $file_size = (Win32::DriveInfo::DriveSpace("$drv:"))[6];
      my $banner=<<'END';

    ___                     _            _     _
   |_ _|_ __  _ __  ___ _ _| |_ __ _ _ _| |_  | |
    | || '  \| '_ \/ _ \ '_|  _/ _` | ' \  _| |_|
   |___|_|_|_| .__/\___/_|  \__\__,_|_||_\__| (_)
             |_|
END
      my $size_file=&size_fmt($file_size);
      $banner.=<<END;

   FullAuto Setup has detected a Cygwin installation at $cygwin_loc.
   Setup has also determined that there is $size_file Free Space on
   the Drive $drv Volume. It is IMPORTANT TO NOTE that FullAuto Setup
   will attempt to use this installation. If this is undesirable, then
   select choice '2' and FullAuto Setup will EXIT. It is recommended
   that you use the cpan utility to install or update FullAuto, if
   there is more than one Cygwin installation on your system.

   If you're sure you wish to proceed with your $cygwin_loc setup,
   then select choice '1' and FullAuto Setup will continue . . .

END
      my %cygchoice=(

            Label => 'cygchoice',
            Item_1 => {
               Text => 'Continue with FullAuto Setup',
            },
            Item_2 => {
               Text => 'CANCEL FullAuto Setup and EXIT',
            },
            Scroll => 1,
            Banner => $banner,

      );
      my $selection=Menu(\%cygchoice);
      chomp($selection);
      if (-1<index $selection,'Continue') {
         my $p='/usr/bin/perl -MCPAN -e';
         my $b="$cygwin_loc/bin/bash -lc";
         select STDOUT;
         $log->close() if $log && -1<index $log,'*';
         exec "$b \"$p 'install Net::FullAuto'\";'fa --new-user'";
      }
      exit if $selection eq ']quit[';
      exit if $selection eq 'CANCEL FullAuto Setup and EXIT';
      $cygwin_root_dir=$cygwin_loc;
   } else {
      my $drv='';
      foreach my $d (Win32::DriveInfo::DrivesInUse()) {
         my $dt=Win32::DriveInfo::DriveType($d);
         next if $dt == 5 || $dt == 4 || !$dt;
         my $FileSystemName=(Win32::DriveInfo::VolumeInfo($d))[3];
         next if $FileSystemName ne 'NTFS';
         my $file_size = (Win32::DriveInfo::DriveSpace("$d:"))[6];
         my $one_gb=1024*1024*1024;
         if ($one_gb<$file_size) {
            $drv=$d;
            if ($dt == 3) {
               push @drive_options, "Drive $d NTFS Fixed Disk ".
                                     &size_fmt($file_size)." Free Space";
            } elsif ($dt == 2) {
               push @drive_options, "Drive $d NTFS Removeable Disk ".
                                     &size_fmt($file_size)." Free Space";
            } else {
               push @drive_options, "Drive $d NTFS Volume ".
                                     &size_fmt($file_size)." Free Space";
            }
         }
      }
      if (-1<$#drive_options) {
         if (0==$#drive_options) {
            if ($^O eq 'MSWin64' || msw64bit()) {
               $cygwin_root_dir="$drv:\\cygwin64";
            } else {
               $cygwin_root_dir="$drv:\\cygwin";
            }
         } else{
            my $banner="\n\n   Please select the Drive/Volume where you ".
                       "would like\n   Cygwin and FullAuto Installed.\n".
                       "\n   ( If you don't see the Drive/Volume you ".
                       "desire,\n     it is probably because the Drive/".
                       "Volume lacks\n     sufficient disk space. At ".
                       "least One Gigabyte\n     of free space is needed ".
                       "for a Windows based\n     Cygwin/FullAuto ".
                       "Installation. )\n\n";
            my %menu_drives=(

               Label => 'menu_drives',
               Item_1 => {

                  Text => "]C[",
                  Convey => \@drive_options,

               },
               Banner => $banner,

            );
            my $selection=Menu(\%menu_drives);
            chomp($selection);
            exit if $selection eq ']quit[';
            $selection=~s/^\s*Drive\s+([A-Z])\s+NTFS.*$/$1/s;
            if ($^O eq 'MSWin64' || msw64bit()) {
               $cygwin_root_dir="$selection:\\cygwin64";
            } else {
               $cygwin_root_dir="$selection:\\cygwin";
            }
         }
      } else {
         print "\n\n   FATAL ERROR! - Insufficient Disk Space.\n".
               "                 At least One Gigabyte (1.0 GB) of\n".
               "                 Free Disk Space is needed to install\n".
               "                 Cygwin and FullAuto on this Windows\n".
               "                 host.".
               "n\n   Please report any bugs and send any",
               "\n   questions, thoughts or feedback to:",
               "\n\n      Brian.Kelly\@FullAuto.com.",
               "\n\n   Press ANY key to exit.\n\n";<STDIN>;
         exit 1;
      }
   }
} elsif (!can_cc() && ((exists $amazon{'amazon_linux'}) ||
      (exists $amazon{'rhel'}) ||
      (exists $amazon{'centos'}))) {

   # Most Amazon images need a lot of helper software like compilers
   # to install all module dependencies. It is assumed users attempting
   # to install Net::FullAuto on an EC2 image have consented to this,
   # especially since Admin privileges are needed to do this.

   my $grpi=`sudo yum grouplist`;
   if (-1<index $grpi,'no installed groups file') {
      my $out=`sudo yum groups mark convert`;
      $grpi=`sudo yum grouplist`;
   }
   my %groups=();my $group_type='';
   foreach my $ln (split "\n",$grpi) {
      if ($ln=~/^(.*) [Gg]roups:$/) {
         $group_type=$1;
         $groups{$group_type}={};
      } else {
         $ln=~/^\s*(.*)$/;
         $groups{$group_type}->{$1}='';
      }
   }
   my $yins=`sudo yum list installed`;
   unless (exists $groups{'Installed'}->{'Development tools'}) {
      fa_system("sudo yum -y update");
      fa_system("sudo yum -y clean all");
      fa_system("sudo yum -y groupinstall 'Development tools'");
   }
   unless (-1<index $yins,'openssl-devel') {
      fa_system("sudo yum -y install 'openssl-devel'");
   }
   if ((exists $amazon{'amazon_linux'}) ||
         (exists $amazon{'rhel'}) ||
         (exists $amazon{'centos'})) {
      unless (-1<index $yins,'wget') {
         fa_system("sudo yum -y install 'wget'");
      }
      fa_system('echo y | sudo amazon-linux-extras install epel');
   }
   unless (-1<index $yins,'figlet') {
      fa_system("sudo yum -y install 'figlet'");
   }
   unless (-1<index $yins,'nano') {
      fa_system("sudo yum -y install 'nano'");
   }

} elsif ((exists $amazon{'amazon_linux'}) || (exists $amazon{'centos'})) {

   # Most Amazon images need a lot of helper software like compilers
   # to install all module dependencies. It is assumed users attempting
   # to install Net::FullAuto on an EC2 image have consented to this,
   # especially since Admin privileges are needed to do this.

   my $yins=`yum list installed`;
   unless (-1<index $yins,'openssl-devel') {
      fa_system("sudo yum -y install 'openssl-devel'");
   }
   unless (-1<index $yins,'wget') {
      fa_system("sudo yum -y install 'wget'");
   }
   unless (-1<index $yins,'figlet') {
      fa_system('echo y | sudo amazon-linux-extras install epel');
      fa_system("sudo yum -y install 'figlet'");
      my $yins=`yum list installed`;
      unless (-1<index $yins,'figlet') {
         fa_system("sudo wget http://dl.fedoraproject.org/pub/epel/7/x86_64/".
                   "Packages/e/epel-release-7-11.noarch.rpm");
         fa_system("sudo rpm -Uvh epel-release*rpm");
         fa_system("sudo yum -y install 'figlet'");
      }
   }
   unless (-1<index $yins,'nano') {
      fa_system("sudo yum -y install 'nano'");
   }

} elsif (!can_cc() && (exists $amazon{'suse'})) {

   # Most Amazon images need a lot of helper software like compilers
   # to install all module dependencies. It is assumed users attempting
   # to install Net::FullAuto on an EC2 image have consented to this,
   # especially since Admin privileges are needed to do this.

   # Manual Setup openSuSE host before CPAN:
   #
   # zypper ar -f -n openSUSE:13.1 
   #    http://download.opensuse.org/distribution/13.1/repo/oss/ openSUSE:13.1
   # zypper -n --gpg-auto-import-keys install --force-resolution wget
   # zypper -n --gpg-auto-import-keys install --force-resolution figlet
   # zypper -n --gpg-auto-import-keys install --force-resolution nano
   # zypper -n install --type pattern Basis-Devel
   # zypper -n install openssl-devel
   # wget http://www.cpan.org/src/5.0/perl-5.20.0.tar.gz
   # tar zxvf perl-5.20.0.tar.gz
   # cd perl-5.20.0
   # ./Configure -d -Dnoextensions=ODBM_File
   # make install
   # cpan
   #

   my $zypper=`/bin/zypper packages -i`;
   if (0 && -1==index $zypper,'gcc') {
      fa_system("zypper -n install --type pattern Basis-Devel");
      fa_system("zypper -n install openssl-devel");
      my $repos='zypper ar -f -n openSUSE:13.1 '.
                'openSUSE:13.1 http://download.'.
                'opensuse.org/distribution/13.1'.
                '/repo/oss/  openSUSE:13.1';
      fa_system($repos);
      my $figlet="zypper -n --gpg-auto-import-keys install".
                 " --force-resolution figlet";
      fa_system($figlet);
      my $nano="zypper -n --gpg-auto-import-keys install".
               " --force-resolution nano";
      fa_system($nano);
   }
      
} elsif (!can_cc() && (exists $amazon{'ubuntu'})) {

   # Most Amazon images need a lot of helper software like compilers
   # to install all module dependencies. It is assumed users attempting
   # to install Net::FullAuto on an EC2 image have consented to this,
   # especially since Admin privileges are needed to do this.

   my $dpkg=`/bin/dpckg -l`;
   my $update_flag=0;
   if (-1==index $dpkg,'build-essential') {
      fa_system("sudo apt-get -y update");
      $update_flag==1;
      fa_system("sudo apt-get -y install 'build-essential'");
   }
   if (-1==index $dpkg,'libssl-dev') {
      unless ($update_flag) {
         fa_system("sudo apt-get -y update");
      }
      fa_system("sudo apt-get -y install 'libssl-dev'");
   }
   if (-1==index $dpkg,'figlet') {
      fa_system("sudo apt-get -y install 'figlet'");
   }
   if (-1==index $dpkg,'nano') {
      fa_system("sudo apt-get -y install 'nano'");
   }
   if (-1==index $dpkg,'perl-doc') {
      fa_system("sudo apt-get -y install 'perl-doc'");
   }

} elsif (!can_cc()) {

   my $moreinfo='';my $s='          ';
   if ($Config{cc} and $Config{cc}!~/^\s*$/) {
      $moreinfo="\n\n$s            You are running $^X version $].\n".
           "\n$s            The Config.pm file for this perl installation".
           "\n$s            contains \"$Config{cc}\" as the compiler used".
           "\n$s            to build this perl, but this compiler does not".
           "\n$s            exist in the PATH and may not be installed on".
           "\n$s            this host.\n".
           "\n$s            Retrofitting an existing perl installation to".
           "\n$s            work properly with a new compiler for building".
           "\n$s            CPAN modules, is tricky and NOT recommended.".
           "\n$s            Often the available perl (especially on Unix".
           "\n$s            systems) is highly integrated with the host".
           "\n$s            OS and many of its features and utilities.".
           "\n$s            Upgrading the system perl, but not the overall".
           "\n$s            OS is risky and may result in more than a".
           "\n$s            few system problems and instabilities.\n".
           "\n$s            The recommended approach is build a NEW perl".
           "\n$s            from source with your choice of newly installed".
           "\n$s            compiler (such as gcc) in a different location".
           "\n$s            (such as /usr/local/lib) or your home directory".
           "\n$s            if you lack root/admin privileges."
   }
   my $die="\n       FATAL ERROR! : A C Compiler (such as cc or gcc)".
           "\n                      is required to install FullAuto".
           $moreinfo.
           "\n                      (Hint: goto www.gnu.org for gcc).".
           "\n\n";
   fa_die($die);

} elsif (exists $amazon{'freebsd'}) {

   # Most Amazon images need a lot of helper software like compilers
   # to install all module dependencies. It is assumed users attempting
   # to install Net::FullAuto on an EC2 image have consented to this,
   # especially since Admin privileges are needed to do this.

   unless (-e '/usr/local/bin/figlet') {
      fa_system("pkg_add -r figlet");
   }
   unless (-e '/usr/local/bin/nano') {
      fa_system("pkg_add -r nano");
   }
} elsif (exists $amazon{'gentoo'}) {

   # Most Amazon images need a lot of helper software like compilers
   # to install all module dependencies. It is assumed users attempting
   # to install Net::FullAuto on an EC2 image have consented to this,
   # especially since Admin privileges are needed to do this.

   unless (-e '/usr/local/bin/figlet') {
      my $fs='ftp://ftp.figlet.org/pub/figlet/program'.
             '/unix/figlet-2.2.5.tar.gz';
      fa_system("(wget $fs;tar zxvf fig*gz;cd figlet-2.2.5;make install)");
   }
}
my $cpantest=0;
$cpantest=1 unless $mycpantest;
use if ($mycpantest), "CPAN::MyConfig";
use if ($cpantest), "CPAN::Config";
   
sub fa_err_exit {
   fa_die("$_[0]\n\n*** Please manually install $_[1]".
       " from cpan.org first...\n");
}

sub fa_find_latest {

   my $temp=0;
   my $look=shift||'';
   unless ($look) {
      fa_die("ERROR - No argument provided to &fa_find_latest().\n");
   }
   $look=~s/::/-/g;
   print "***** Looking for Most Recent \"$look Dir\" \n";
   eval {
      local $SIG{__DIE__}; # No sigdie handler
      CPAN::HandleConfig->load;
   };
   my $d = $CPAN::Config->{build_dir};
   if (!(defined $d) || !(-d $d)) {
      $d=(getpwuid $>)[7].'/.cpan/build';
      unless (-d $d) {
         unless (-d "/root/.cpan/build") {
            fa_die("ERROR - Can't locate .cpan/build directory");
         } else {
            $d='/root/.cpan/build';
         }
      }
   }
   my $new='';my $file='';
   opendir(DH,$d) or
      fa_die("ERROR - Can't read Directory $d: $!\n");
   while ($_ = readdir(DH)) {
      next if ($_ eq ".") || ($_ eq "..") || (/\.yml$/);
      if ($_!~/^$look[-][vV]?\d/) {
         if (-d $d.'/'.$_) {
            my $dr=$d.'/'.$_;
            $new=&look_inside_dir($dr,$look);
         } next
      }
      $file=sprintf("%s/%s",$CPAN::Config->{build_dir},$_);
      my $attrs = stat $file;
      my $diff = time()-$attrs->[9];
      if ($temp == 0 && $_=~/^$look[-][vV]?\d/) {
         $temp=$diff;
         $new=$file;
      }
      if ($diff<$temp) {
         $temp=$diff;
         $new=$_;
      }
   }
   close(DH);
   $new=$file if !$new && $file;
   print "***** Module Directory ",$new,"\n";
   return $new; 
}

sub look_inside_dir {

   my $d=$_[0];
   my $look=$_[1];
   my $found='';
   opendir(LI,$d) or
      fa_die("ERROR - Can't read Directory $d: $!\n");
   my $tar='';
   while ($_ = readdir(LI)) {
      next if ($_ eq ".") || ($_ eq "..");
      if ($_=~/[.]tar$/ && $_=~/^$look[-][vV]?\d/) {
         $tar=$_;
         next;
      }
      if ($_=~/^$look[-][vV]?\d/ && -d $_) {
         $tar='';
         last;
      }
   }
   close(LI);
   if ($tar) {
      unless ($CPAN::Config->{tar}) {
         if (-e '/usr/sfw/bin/gtar') {
            $CPAN::Config->{tar}='/usr/sfw/bin/gtar';
         } elsif (-e '/usr/bin/tar') {
            $CPAN::Config->{tar}='/usr/bin/tar';
         } elsif (-e '/usr/local/bin/tar') {
            $CPAN::Config->{tar}='/usr/local/bin/tar';
         } else {
            print "\n\n   FATAL ERROR!: The 'tar' utility is".
               " missing.\n".
               "\n\n   Please report any bugs and send any",
               "\n   questions, thoughts or feedback to:",
               "\n\n      Brian.Kelly\@FullAuto.com.",
               "\n\n   Press ANY key to exit.\n\n";<STDIN>;
               exit 1;
         }
      }
      chdir $d;
      if (($system_type eq 'amazon_linux') ||
            ($system_type eq 'ubuntu') ||
            ($system_type eq 'rhel') ||
            ($system_type eq 'centos')) {
         print "***** Untar: sudo ",$CPAN::Config->{tar}," xvf $tar\n";
         fa_system("sudo ".$CPAN::Config->{tar}." xvf $tar");
      } else {
         print "***** Untar: ",$CPAN::Config->{tar}," xvf $tar\n";
         fa_system($CPAN::Config->{tar}." xvf $tar");
      }
      chdir $CPAN::Config->{build_dir};
      $tar=~s/[.]tar$//;
      return "$d/$tar";
   }
   return '';

}
   
sub fa_install_mod {
   
   my $p=$_[0];
   my $task=$_[1];
   my $butil=$_[2]||'';
   my $force=$_[3]||'';
   my $version=$_[4]||'';
   my $echo=$_[5]||'';
   my $env=$_[6]||'';
   my $dir='';
   my $cpan_error='';
   eval {
      local $SIG{__DIE__}; # No sigdie handler
      require CPAN::Mini;
      import CPAN::Mini;
   };
   if (!$@ && grep { /-*add[-_]?dependencies/i } @ARGV) {
      my $distribution = CPAN::Shell->expand(
            "Module",$p 
         )->distribution()->pretty_id();
      my $let=unpack('a1',$distribution);
      my $lett=unpack('a2',$distribution);
      my $minicpan=CPAN::Mini->new(

         #remote => "http://www.cpan.org",
         remote => "http://www.perl.com/CPAN",
         local  => cwd()."/dependencies/CPAN",
         log_level => 'debug',
         exact_mirror => 1,
      
      );
      $minicpan->mirror_file(
         "authors/id/$let/$lett/$distribution");
   }
   my $mod_info='';my $instfile='';my $cpanfil='';
   if (!$version || (grep {
         /(?:use[-_]?)?internet|online|connect_to_internet_ok/i
         } @ARGV)) {
      local $SIG{__DIE__}; # No sigdie handler
      CPAN::Shell->m($p);
      eval {
         local $SIG{__DIE__}; # No sigdie handler;
         require CPAN;
         {
            local *STDOUT;
            open(STDOUT, ">", \$mod_info);
            CPAN::Shell->m($p);
         }
      };
      my $instver='';my $cpanver='';
      if ($mod_info) {
         ($instfile=$mod_info)=~s/^.*INST_FILE\s+([^\s]+).*$/$1/s;
         ($instver=$mod_info)=~s/^.*INST_VERSION\s+([^\s]+).*$/$1/s;
         ($cpanfil=$mod_info)=~s/^.*CPAN_FILE\s+([^\s]+).*$/$1/s;
         ($cpanver=$mod_info)=~s/^.*CPAN_VERSION\s+([^\s]+).*$/$1/s;
      }
      if (!$version && ($instver<$cpanver)) {
         unlink $instfile if $exec_cnt;
         $version=$cpanver;
      }
   } else {
      $cpanfil=$p;
   }
   {
      local $SIG{__DIE__}; # No sigdie handler
      eval "require $p;1";
   };
   my $ver='';
   my $testp=$p;
   $testp=~s/::/\//g;
   unless ($@) {
      if ($version) {
         my $ttmp='$ver=$'.$p.'::VERSION';
         eval $ttmp;
         $ver=eval $ver;
         $force=($ver<$version)?1:0;
      } else { $force=0 } 
   } elsif ($@=~/attempt to reload/is){
      delete $INC{$p};
      {
         local $SIG{__DIE__}; # No sigdie handler
         eval "require $p;1";
      };
      if ($@) {
         print "\n\n";
         print "   FATAL ERROR!: $@\n\n";
         exit 1;
      } return '';
   #} elsif ((-1<index $@,"Can't locate") &&
     #    (-1==index $@,$testp)) {
     # print "\n\n";
     # print "   FATAL ERROR!: $@\n\n";
     # exit 1;
   }
   if ($@ || $instfile eq '(not' || $force) {
      if ($ENV{'AUTOMATED_TESTING'}) {
         print "Automated Testing Detected: FullAuto needs $p\n",
               "   to continue, but $p was not detected on this\n",
               "   host.\n\n";
               "FullAuto Install will EXIT.";
         exit 1;
      }
      if ($version && $p eq 'Term::Menus') {
         $p="REEDFISH/Term-Menus-$version.tar.gz";
      } elsif ($version && $p eq 'Term::RawInput') {
         $p="REEDFISH/Term-RawInput-$version.tar.gz";
      }
      print "==> $p required."
      and print "*** Installing $p via CPAN\n"
      and
      eval {
         local $SIG{__DIE__}; # No sigdie handler;
         require CPAN;
         CPAN::Shell->notest('get',$p);
      };
      if ($@) {
         fa_die("CPAN Error: $@ $!\n");
      }
      if ($version && (-1<index $p,'Term-Menus')) {
         $p='Term::Menus';
      } elsif ($version && (-1<index $p,'Term-RawInput')) {
         $p='Term::RawInput';
      }
      if (lc($task) eq 'install') {
         my $sudo='';
         if (($system_type eq 'amazon_linux') ||
               ($system_type eq 'ubuntu') ||
               ($system_type eq 'rhel') ||
               ($system_type eq 'centos')) {
            $sudo='sudo ';
         }
         $cpanfil=~s/^.*\/(.*)$/$1/;
         $cpanfil=~s/^(.*)-.*$/$1/;
         $cpanfil=~s/-/::/;  
         $dir||=&fa_find_latest($cpanfil);
         print "*** Running $sudo$^X $butil.PL\n";
         print "*** cd to $dir\n";
         if ($p eq 'Archive::Tar') {
            my @MakefilePL=();
            open(FH,"<$dir/Makefile.PL");
            @MakefilePL=<FH>;
            close FH;
            my $newfile='';
            foreach my $line (@MakefilePL) {
               if ($line=~/sleep 10/) {
                  $newfile.="#$line";
               } else {
                  $newfile.=$line;
               }
            }
            unlink "$dir/Makefile.PL";
            open(FH,">$dir/Makefile.PL");
            print FH $newfile;
            close FH;
         } elsif ($p eq 'libnet') {
            open (FH,">$dir/libnet.cfg");
            close FH;
         } elsif ($p eq 'Win32::API') {
            open(FH,"<$dir/Callback/Callback.xs");
            my @callback=<FH>;
            close FH;
            my $new_callback=join '', @callback;
            my $newfile='';
            unless (-1<index $new_callback,'stricmp') {
               foreach my $line (@callback) {
                  if ($line=~/WIN32_LEAN_AND_MEAN/) {
                     $newfile.="\n#ifndef WIN32"
                             ."\n#       define stricmp strcasecmp"
                             ."\n#       define strnicmp strncasecmp"
                             ."\n#endif\n";
                  }
                  $newfile.=$line;
               }
               open(FH,">$dir/Callback/Callback.xs");
               print FH $newfile;
               close FH;
            }
         } elsif ($p eq 'Win32::OLE') {
            open(FH,"<$dir/OLE.xs");
            my @ole=<FH>;
            close FH;
            my $newole=join '', @ole;
            $newole=~s/stricmp/strcasecmp/sg;
            open(FH,">$dir/OLE.xs");
            print FH $newole;
            close FH;
         }
         $env="export $env;" if $env;
         my $s='';
         $s="${sudo}-E " if $sudo && $env;
         if ($echo) {
            fa_system("${env}cd \"$dir\";echo $echo | $s$^X $butil.PL");
         } else {
            fa_system("${env}cd \"$dir\";$s$^X $butil.PL");
         }
         open(FH,"<$dir/Makefile");
         my @makefile=<FH>;
         close FH;
         my $newmakefile=join '', @makefile;
         $newmakefile=~s/-Werror=format-security //sg;
         open(FH,">$dir/Makefile");
         print FH $newmakefile;
         close FH;
         if ($butil eq 'Makefile') {
            print "*** Running ${sudo}make install\n";
            fa_system("cd \"$dir\";${sudo}make install");
         } else {
            print "*** Running ${sudo}Build install\n";
            fa_system("cd \"$dir\";./Build build;${sudo}./Build install");
         }
      }
      chdir $cwd;
      my $_p=$p;
      $_p=~s/::/\//g;
      $_p.='.pm';
      unless (exists $INC{$_p}) {
         eval {
            local $SIG{__DIE__}; # No sigdie handler
            require $_p;
         };
         if ($@ && -1==index $@,'Attempt to reload') {
            warn $@;
         } else {
            print "*** $p Loaded Successfully\n";
            $exec_cnt=0;
         }
      } elsif (lc($task) eq 'install') {
         my $sudo=0;
         if (($system_type eq 'amazon_linux') ||
               ($system_type eq 'ubuntu') ||
               ($system_type eq 'rhel') ||
               ($system_type eq 'centos')) {
            $sudo=1;
         }
         my $argvs=join " ", @ARGV;
         select STDOUT;
         $log->close() if $log && -1<index $log,'*';
         if ($sudo) {
            exec "sudo $^X Makefile.PL $argvs SKIP $p $exec_cnt";
         } else {
            exec "$^X Makefile.PL SKIP $argvs $p $exec_cnt";
         }
      }
   } else {
      print "*** $p Loaded Successfully\n";
      $exec_cnt=0;
   }
   return '';
}
   
sub fa_install_module {
    my $stdout='';my $stderr='';
    eval {
       local $SIG{__DIE__}; # No sigdie handler 
       require Capture::Tiny
    };
    if ($@) {
       eval { &fa_install_mod(@_) };
       if ($@) {
          &fa_err_exit($@,$_[0]);
       }
    } else {
       my ($stdout_capture,$stderr_capture)=('','');
       eval {
          local $SIG{__DIE__}; # No sigdie handler
          require Capture::Tiny;
          ($stdout_capture,$stderr_capture)=
                Capture::Tiny::capture {
             &fa_install_mod(@_)
          };
       };
       print $stdout_capture if $stdout_capture;
       &fa_err_exit($stderr_capture,$_[0])
          if $stderr_capture;
    }
}
   
sub menu {
   my $m = shift;
   my $choice;
   while (1) {
      print "$m->[0]\n";
      print map { "\t$_. $m->[$_][0]\n" } (1..$#$m);
      print "\n\n   PLEASE ENTER A CHOICE: ";
      chomp ($choice = <STDIN>);
      last if ( ($choice > 0) && ($choice <= $#$m ));
      print "You chose '$choice'.  That is not a valid option.\n\n";
   }
   &{$m->[$choice][1]};
}

sub size_fmt {
   my $size = shift(@_);

   if ($size < 1024) {
      return $size . " bytes";
   }
   if ($size < (1024*1024)) {
      return sprintf("%.2f KB",$size / 1024);
   }
   if ($size < (1024*1024*1024)) {
      return sprintf("%.2f MB",$size / (1024*1024));
   }
   if ($size < (1024*1024*1024*1024)) {
      return sprintf("%.2f GB",$size / (1024*1024*1024));
   }
   return sprintf("%.2f TB",$size / (1024*1024*1024*1024));
}

my $stdout='';my $stderr='';
if ($^O ne 'MSWin32' && $^O ne 'MSWin64') {
   &fa_install_mod('ExtUtils::MakeMaker','install','Makefile');
   &fa_install_mod('File::Which','install','Makefile');
   &fa_install_module('Term::ReadKey','install','Makefile');
   &fa_install_mod('Perl::OSType','install','Makefile');
   &fa_install_mod('Locale::Maketext::Simple','install','Makefile');
   eval {
      local $SIG{__DIE__}; # No sigdie handler;
      require Test::Tester;
   };
   if ($@) {
      &fa_install_mod('Test::Simple','install','Makefile');
   } else {
      &fa_install_mod('Test::Simple','install','Makefile');
      &fa_install_mod('Test::Tester','install','Makefile');
   }
   &fa_install_mod('Params::Check','install','Makefile');
   &fa_install_mod('version','install','Makefile');
   &fa_install_mod('Module::CoreList','install','Makefile');
   &fa_install_mod('Module::Load','install','Makefile');
   &fa_install_mod('parent','install','Makefile');
   &fa_install_mod('Module::Metadata','install','Makefile');
   &fa_install_mod('Module::Load::Conditional','install','Makefile');
   &fa_install_mod('IPC::Cmd','install','Makefile');
   &fa_install_mod('ExtUtils::CBuilder','install','Makefile');
   &fa_install_mod('Mo','install','Makefile');
   &fa_install_mod('YAML','install','Makefile');
   &fa_install_mod('YAML::Tiny','install','Makefile');
   &fa_install_mod('Algorithm::Diff','install','Makefile');
   &fa_install_mod('Text::Diff','install','Makefile');
   &fa_install_mod('PAR::Dist','install','Makefile');
   &fa_install_mod('IO::Compress::Base::Common','install','Makefile');
   &fa_install_mod('Compress::Raw::Bzip2','install','Makefile');
   &fa_install_mod('Compress::Raw::Zlib','install','Makefile');
   &fa_install_mod('Compress::Zlib','install','Makefile');
   &fa_install_mod('CPAN::Meta::YAML','install','Makefile');
   &fa_install_mod('Parse::CPAN::Meta','install','Makefile');
   &fa_install_mod('CPAN::Meta::Requirements','install','Makefile');
   &fa_install_mod('JSON::PP','install','Makefile');
   my $mod_info='';my $mod_build_version=0.3601;
   unless (-e "dependencies/CPAN/authors" &&
         !(grep {
         /(?:use[-_]?)?internet|online|connect_to_internet_ok/i } @ARGV)) {
      eval {
         local $SIG{__DIE__}; # No sigdie handler;
         require CPAN;
         {
            local *STDOUT;
            open(STDOUT, ">", \$mod_info);
            CPAN::Shell->m('Module::Build');
         }
      };
      unless ($@) {
         my $instfile='';my $instver='';my $cpanver='';
         if ($mod_info) {
            ($instfile=$mod_info)=~s/^.*INST_FILE\s+([^\s]+).*$/$1/s;
            ($instver=$mod_info)=~s/^.*INST_VERSION\s+([^\s]+).*$/$1/s;
            ($cpanver=$mod_info)=~s/^.*CPAN_VERSION\s+([^\s]+).*$/$1/s;
         }
         if ($instver<$cpanver) {
            $mod_build_version=$cpanver;
         }
      }
   }
   eval {
      local $SIG{__DIE__}; # No sigdie handler;
      require Module::Build;
   };
   if ((!($@) && $Module::Build::VERSION<=$mod_build_version) || $@
         || grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_mod('ExtUtils::ParseXS','install','Makefile');
      &fa_install_mod('Compress::Raw::Bzip2','install','Makefile');
      &fa_install_mod('Compress::Raw::Zlib','install','Makefile');
      &fa_install_mod('IO::Zlib','install','Makefile');
      &fa_install_mod('Archive::Tar','install','Makefile');
      &fa_install_mod('inc::latest','install','Makefile');
      &fa_install_mod('Regexp::Common','install','Makefile');
      &fa_install_mod('Pod::Checker','install','Makefile');
      &fa_install_mod('Pod::Parser','install','Makefile');
      &fa_install_mod('Pod::Man','install','Makefile');
      &fa_install_mod('Module::Build','install','Makefile','force');
   }
   #&fa_install_mod('IO::CaptureOutput','install','Makefile');
   #REPLACE BY Capture::Tiny
   if ($^O ne 'MSWin32' && $^O ne 'MSWin64' ||
         grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_module('IO::Pty','install','Makefile');
      unless (grep { /-*add[-_]?dependencies/i } @ARGV) {
         my $argv0=$ARGV[0]||'';
         exit if $argv0 eq 'install_IO_Pty_from_CPAN';
      }
   }
   &fa_install_module('IO::Tee','install','Makefile');
   &fa_install_module('HTML::Tagset','install','Makefile');
   &fa_install_module('HTML::Parser','install','Makefile');
   &fa_install_module('URI','install','Makefile');
   &fa_install_module('HTTP::Date','install','Makefile');
   &fa_install_module('Digest::MD5','install','Makefile');
   &fa_install_module('LWP::MediaTypes','install','Makefile');
   &fa_install_module('Encode::Locale','install','Makefile');
   &fa_install_module('IO::HTML','install','Makefile');
   &fa_install_module('HTTP::Message','install','Makefile');
   &fa_install_module('File::Listing','install','Makefile');
   &fa_install_module('HTTP::Cookies','install','Makefile');
   if ($^O ne 'cygwin'
         || grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_module('HTTP::Daemon','install','Makefile');
   }
   &fa_install_module('WWW::RobotRules','install','Makefile');
   &fa_install_module('Date::Format','install','Makefile');
   &fa_install_module('Date::Parse','install','Makefile');
   &fa_install_module('Mail::Internet','install','Makefile');
   &fa_install_module('Mail::Header','install','Makefile');
   &fa_install_module('Mail::Field','install','Makefile');
   &fa_install_module('Test::NoWarnings','install','Makefile');
   &fa_install_module('Convert::BinHex','install','Makefile');
   &fa_install_module('Test::Deep','install','Makefile');
   &fa_install_module('MIME::Base64','install','Makefile');
   &fa_install_module('MIME::Entity','install','Makefile');
   &fa_install_module('LWP::MediaTypes','install','Makefile');
   &fa_install_module('HTTP::Negotiate','install','Makefile');
   &fa_install_module('Net::HTTP','install','Makefile');
   &fa_install_module('Data::Dump','install','Makefile');
   &fa_install_module('File::HomeDir','install','Makefile');
   &fa_install_module('Test::Fatal','install','Makefile');
   &fa_install_module('Test::Needs','install','Makefile');
   &fa_install_module('Test::RequiresInternet','install','Makefile');
   &fa_install_module('Try::Tiny','install','Makefile');
   &fa_install_module('LWP','install','Makefile');
   &fa_install_module('CPAN::Mini','install','Makefile');
   eval {
      local $SIG{__DIE__}; # No sigdie handler
      require Net::SSLeay;
   };
   if ($@) {
      my $ssleay_error_banner=<<END;

         *** THIS SCREEN WILL TIMEOUT AND FULLAUTO SETUP WILL EXIT
                    IN 5 MINUTES IF NO CHOICE IS MADE ***

      FullAuto Setup ERROR: Missing dependency 'openssl-devel'

   The CPAN module Net::SSLeay requires the 'openssl-devel' system package to
   be installed. Would you like FullAuto Setup to attempt installing this
   package?
END
      &fa_install_module('Net::SSLeay','get');
      my $dir=&fa_find_latest('Net-SSLeay');
      fa_system("(cd \"$dir\";echo n | $^X Makefile.PL) 2>&1");
      SSL: while (1) {
         open(FH, "(cd \"$dir\";make install) 2>&1|");
         while (my $line=<FH>) {
            if (-1<index $line,
                  'error: openssl/err.h: No such file or directory') {
               my $timeout=300;my $selection='';
               {
                  local $SIG{__DIE__}; # No sigdie handler
                  eval {
                     local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
                     alarm $timeout;
                     my $fae="No   (FullAuto Setup will exit)";
                     my $menu1 = [
                                 $ssleay_error_banner,
                                 [ "Yes", sub{ return 'Yes' } ],
                                 [ $fae, sub{ return 'No' } ],
                                 ];
                     $selection=&menu($menu1);
                     exit if $selection eq ']quit[';
                     alarm 0;
                  };
                  if ($@) {
                     # timed out
                     $selection = 'No';
                  }
                  if ($selection=~/No/) {
                     exit;
                  } alarm 0;
               };
               if (($system_type eq 'amazon_linux') ||
                     ($system_type eq 'rhel') ||
                     ($system_type eq 'centos') ||
                     ($system_type eq 'fedora')) {
                  fa_system("sudo yum -y install 'openssl-devel'");
                  next SSL;
               } elsif ($system_type eq 'suse') {
                  fa_system("zypper -n install openssl-devel");
                  next SSL;
               } elsif ($system_type eq 'ubuntu') {
                  fa_system("sudo apt-get -y install 'libssl-dev'");
                  next SSL;
               }
            }
            print $line;
         } last;
      }
      close FH;
   } elsif (grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_module('Net::SSLeay','get');
   }
   &fa_install_module('IO::Socket::SSL','install','Makefile','','','n');
   &fa_install_module('Mozilla::CA','install','Makefile');
   &fa_install_module('LWP::Protocol::https','install','Makefile');
   &fa_install_module('Task::Weaken','install','Makefile');
   &fa_install_module('ExtUtils::Depends','install','Makefile');
   &fa_install_module('B::Utils','install','Makefile');
   &fa_install_module('ExtUtils::Config','install','Makefile');
   &fa_install_module('ExtUtils::InstallPaths','install','Makefile');
   &fa_install_module('ExtUtils::Helpers','install','Makefile');
   &fa_install_module('Test::Harness','install','Makefile','','3.33');
   &fa_install_module('Module::Build::Tiny','install','Build');
   &fa_install_module('Class::Method::Modifiers','install','Makefile');
   &fa_install_module('common::sense','install','Makefile');
   &fa_install_module('Types::Serialiser','install','Makefile');
   &fa_install_module('Term::RawInput','install','Makefile');
   if ($^O eq 'cygwin' || grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_module('Encode::compat','install','Makefile');
      &fa_install_module('Win32::API','install','Makefile');
      &fa_install_module('Win32::DriveInfo','install','Makefile');
      &fa_install_module('Devel::PL_origargv','install','Makefile');
      &fa_install_module('Win32::OLE','install','Makefile');
      &fa_install_module('Win32::RunAsAdmin','install','Makefile');
   }
   $ENV{PERL_CANARY_STABILITY_NOPROMPT}=1;
   &fa_install_module('Canary::Stability','install','Makefile');
   my $cpanvalue=$ENV{PERL5_CPAN_IS_RUNNING}||'';
   my $cpanmvalue=$ENV{PERL5_CPANM_IS_RUNNING}||'';
   undef $ENV{PERL5_CPAN_IS_RUNNING};
   undef $ENV{PERL5_CPANM_IS_RUNNING};
   &fa_install_module('JSON::XS','install','Makefile');
   &fa_install_module('JSON','install','Makefile');
   $ENV{PERL5_CPAN_IS_RUNNING}=$cpanvalue if $cpanvalue;
   $ENV{PERL5_CPANM_IS_RUNNING}=$cpanmvalue if $cpanmvalue;
   &fa_install_module('Devel::Symdump','install','Makefile');
   &fa_install_module('PadWalker','install','Makefile');
   eval {
      local $SIG{__DIE__}; # No sigdie handler
      require Data::Dump::Streamer;
   };
   if ($@ || grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_module('Data::Dump::Streamer','get');
      unless (grep { /-*add[-_]?dependencies/i } @ARGV) {
         my $dir=&fa_find_latest('Data-Dump-Streamer');
         fa_system("cd \"$dir\";$^X Build.PL NODDS;");
         fa_system("cd \"$dir\";./Build install;");
      }
   }
   &fa_install_module('Capture::Tiny','install','Makefile');
   &fa_install_module('Term::Menus','install','Makefile');
   &fa_install_module('IO::String','install','Makefile');
   &fa_install_module('Crypt::CBC','install','Makefile');
   &fa_install_module('Crypt::DES','install','Makefile');
   &fa_install_module('Test::Manifest','install','Makefile');
   &fa_install_module('Crypt::Rijndael','install','Makefile');
   &fa_install_module('Clone','install','Makefile');
   &fa_install_module('File::Remove','install','Makefile');
   &fa_install_module('Exporter::Tiny','install','Makefile');
   &fa_install_module('List::Util','install','Makefile');
   &fa_install_module('List::MoreUtils','install','Makefile');
   &fa_install_module('Params::Util','install','Makefile');
   &fa_install_module('Test::Object','install','Makefile');
   &fa_install_module('Hook::LexWrap','install','Makefile');
   &fa_install_module('Test::SubCalls','install','Makefile');
   &fa_install_module('Class::Inspector','install','Makefile');
   &fa_install_module('PPI','install','Makefile');
   &fa_install_module('Tie::Cache','install','Makefile');
   &fa_install_module('String::Random','install','Build');
   &fa_install_module('Net::Telnet','install','Makefile');
   &fa_install_module('Sort::Versions','install','Makefile');
   &fa_install_module('IO::Capture','install','Makefile');
   &fa_install_module('Pod::Man','install','Makefile');
   &fa_install_module('Sub::Exporter::Progressive','install','Makefile');
   &fa_install_module('MRO::Compat','install','Makefile');
   &fa_install_module('Sub::Install','install','Makefile');
   &fa_install_module('Data::OptList','install','Makefile');
   &fa_install_module('B::Hooks::OP::Check','install','Makefile');
   &fa_install_module('Lexical::SealRequireHints','install','Build');
   &fa_install_module('multidimensional','install','Makefile');
   &fa_install_module('bareword::filehandles','install','Makefile');
   &fa_install_module('indirect','install','Makefile');
   &fa_install_module('strictures','install','Makefile');
   &fa_install_module('Role::Tiny','install','Makefile');
   &fa_install_module('Devel::GlobalDestruction','install','Makefile');
   &fa_install_module('Module::Runtime','install','Makefile');
   &fa_install_module('Import::Into','install','Makefile');
   &fa_install_module('Sub::Exporter','install','Makefile');
   &fa_install_module('Sub::Exporter::Util','install','Makefile');
   &fa_install_module('Sub::Defer','install','Makefile');
   &fa_install_module('Sub::Quote','install','Makefile');
   &fa_install_module('Moo','install','Makefile');
   &fa_install_module('MooX::Types::MooseLike','install','Makefile');
   &fa_install_module('MooX::Types::MooseLike::Base','install','Makefile');
   &fa_install_module('Devel::StackTrace','install','Makefile');
   &fa_install_module('Throwable','install','Makefile');
   &fa_install_module('Email::Date::Format','install','Makefile');
   &fa_install_module('Net::SMTP','install','Makefile','','','','PERL_CORE=1');
   &fa_install_module('Email::Simple','install','Makefile');
   &fa_install_module('Email::Address','install','Makefile');
   &fa_install_module('Module::Pluggable','install','Makefile');
   &fa_install_module('Email::Abstract','install','Makefile');
   &fa_install_module('Email::Sender','install','Makefile');
   &fa_install_module('URI::Escape::XS','install','Makefile');
   &fa_install_module('Proc::ProcessTable','install','Makefile');
   &fa_install_module('Data::Password::Check','install','Makefile');
   &fa_install_module('Crypt::GeneratePassword','install','Makefile');

}

my %cygsrvs=();
my @output=();
my $hostname=`hostname`;
chomp($hostname);

sub ws_info {
   my $selection='';
   if ($_[0]) {
      print "\nRunning command: net user /domain ->".
            " This may take a couple of minutes\n\n";
   }
   # Do we have Cygwin?
   my $cygwin_loc=get_cygwin_location();
   my $clo=$cygwin_loc;
   $clo=~s/\\/\\\\/g;
   my %userlist=();my %passlins=();
   my @newpassw=();my $modflag=0;
   if (-e $cygwin_loc."/bin") {
      my $pasen='SET CYGWIN=nodosfilewarning & '.
                "cmd /c $cygwin_loc\\bin\\bash -lc ".
                '"cat /etc/passwd"';
      my $passe=`$pasen`;my $cnt=0;my %passlins=();
      foreach my $en (split "\n",$passe) {
         chomp($en);
         push @{$passlins{$en}},$cnt++;
         push @newpassw,$en;
      }
      foreach my $lin (keys %passlins) {
         my $linn=$lin;
         my @pl=@{$passlins{$linn}};
         if (0<$#pl) {
            my %asklin=(
               Label => 'asklin',
               Item_1 => {
                  Text => "]C[",
                  Convey => sub {

                     my @ret=();
                     foreach my $p (@pl) {
                        push @ret, "\n                $linn\n".
                                   "\n                Line: $p\n\n";
                     }
                     return @ret;

                  },
               },
               Item_2 => {
                  Text => "Skip this operation",
               },
               Banner => "   Duplicate Lines in /etc/passwd found!\n\n".
                         "   The following lines are all duplicates, ".
                         "the only one being utilized is\n   the first ".
                         "one found. It is recommended that the ".
                         "others be removed.\n\n".
                         "   Select the one you wish to keep, or choose ".
                         "'Skip this operation' and\n   FullAuto Setup ".
                         "will continue.\n\n",
            );
            my $select=Menu(\%asklin);
            chomp($select);
            exit if $select eq ']quit[';
            my $s=0;
            ($s=$select)=~s/^.*\n\s+Line: (\d+).*$/$1/s;
            my $adjust=0;
            foreach my $i (@pl) {
               my $ii=$i;
               my $n=0;
               ($n=$ii)=~s/^.*\n\s+Line: (\d+).*$/$1/s;
               next if $s eq $n;
               $n-=$adjust;
               splice(@newpassw,$n,1);
               $modflag=1;
               $adjust++;
            }
         }
      }
      if ($modflag) {
         my $npass=join "\n",@newpassw;
         open(NP,">$cygwin_loc/etc/passwd");
         foreach my $l (@newpassw) {
            print NP "$l\n";
         }
         close NP;
      } $modflag=0;
      my $users='SET CYGWIN=nodosfilewarning & '.
                "cmd /c $cygwin_loc\\bin\\bash -lc ".
                '"cat /etc/passwd |grep '.
                '\\"/bin/bash\\" |grep '.
                '\\"[5-9][0-9][0-9]\\""';
      my $userlist=`$users`;
      my %ulist=();my $cyguser='';
      foreach my $us (split "\n",$userlist) {
         chomp($us);
         $cyguser=substr($us,0,(index $us,':'));
         next if $cyguser ne 'cyg_server';
         push @{$ulist{$cyguser}}, $us;
      }
      my @u=@{$ulist{cyg_server}};
      my @list=();my @retrn=();
      my $domain_id_flag=0;
      my $local_id_flag=0;
      my %cygsrvs=();
      if (-1<$#u) {
         foreach my $e (@u) {
            my @it=split ':',$e;
            my $info=(split ',',$it[4])[1];
            my $d='';my $i='';
            if (-1<index $info,'\\') {
               ($d,$i)=split /\\/,$info;
               $d=~s/^.*-(.*)$/$1/;
               $d="DOMAIN: $d";
               $domain_id_flag=1;
            } else {
               $d="LOCAL: $hostname";
               $local_id_flag=1;
            }
            push @retrn,"cyg_server -> $d";
            $cygsrvs{"cyg_server -> $d"}=$e;
         }
      }
      if (0<$#retrn) {
         my %askcyg=(

            Label => 'askcyg',
            Item_1 => {

               Text => "]C[",
               Convey => \@retrn,

            },
            Banner => "   More than one instance of the user 'cyg_server'\n" .
                      "   have been located in the /etc/passwd file. However".
                      ",\n   only one can be used. Please choose one:\n",
         );
         my $select=Menu(\%askcyg);
         chomp($select);
         exit if $select eq ']quit[';
         delete $cygsrvs{$select};
         my $pasen='SET CYGWIN=nodosfilewarning & '.
                   "cmd /c $cygwin_loc\\bin\\bash -lc ".
                   '"cat /etc/passwd"';
         my $passe=`$pasen`;my $cnt=0;my %passlins=();
         foreach my $en (split "\n",$passe) {
            chomp($en);
            push @{$passlins{$en}},$cnt++;
            push @newpassw,$en;
         }
         my $ct=0;my $n=0;my $modflag=0;
         foreach my $lin (keys %passlins) {
            my $linn=$lin;
            $lin=~s/\s*$//;
            foreach my $i (values %cygsrvs) {
               my $ii=$i;
               $ii=~s/\s*$//;
               if ($lin eq $ii) {
                  splice(@newpassw,$n,1);
                  $ct++;
                  $modflag=1;
                  next;
               }
               $ct++;$n++;
            }
         }
         if ($modflag) {
            open(NP,">$cygwin_loc/etc/passwd");
            foreach my $l (@newpassw) {
               print NP "$l\n";
            }
            close NP;
         }
         test_windows_user_rights('cyg_server');
      }
   }
   my $found_dotted=0;
   my $domain='';
   $domain=' /domain' if $_[0];
   my $server='';
   foreach my $line (split "\n", `net user$domain 2>&1`) {
      unless ($found_dotted) {
         if (-1<index $line,'-------') {
            $found_dotted=1;
         } elsif (-1<index $line,' for domain ') {
            ($domain=$line)=~s/^.* for domain (.*)[.]\s*$/$1/s;
         } elsif (-1<index $line,' accounts for ') {
            ($server=$line)=~s/^.* accounts for\s+(.*)\s*$/$1/s;
         }
         next;
      }
      push @output, $line;
   }
   my $limit=9;
   $limit=$#output if $#output<9;
   my @test=@output[0..$limit];
   my %testone=();
   my %testtwo=();
   while (my $line=shift @test) {
      $line=~tr/\0-\11\13-\37\177-\377//d;
      chomp($line);
      $line=~s/\s*$//s;
      my $ln2=rindex $line, ' ';
      $testtwo{$ln2}++;
      substr($line,$ln2)='';
      $line=~s/\s*$//s;
      my $ln1=rindex $line, ' ';
      $testone{$ln1}++;
   }
   my $two=0;
   foreach my $key (keys %testtwo) {
      $two=$key if $two<$key;
   }
   my $one=0;
   foreach my $key (keys %testone) {
      $one=$key if $one<$key;
   }
   $one++;
   my $mid=$two-$one+1;
   my @users=();my $cyg_id='';
   my $success_flag=0;
   foreach my $line (@output) {
      my ($on,$tw,$th)=unpack("a$one a$mid a$two",$line);
      $on=~s/\s*$//;$tw=~s/\s*$//;$th=~s/\s*$//;
      if (-1<index $on,'The command compl') {
         $success_flag=1;
         last;
      }
      push @users, $on if $on;
      $cyg_id='cyg_server' if $on eq 'cyg_server';
      push @users, $tw if $tw;
      $cyg_id='cyg_server' if $tw eq 'cyg_server';
      push @users, $th if $th;
      $cyg_id='cyg_server' if $th eq 'cyg_server';

   }

   my $dom=(defined $_[0] && $_[0])?$_[0]:'Local';

   if ($dom ne 'Local' && !$success_flag) {

      my $banner='';my $op=join '', @output;
      if ((-1<$#output) && ($op!~/^\s*$/s)) {
         my $op=join "\n",@output;
         $banner=<<END;

   IMPORTANT! - The Windows command: net user /domain -> ERROR!

      $op
      
   If you intend to use a Windows Domain Account for the Cygwin sshd
      service it is helpful that the FullAuto Installer be able to query
      the $dom Domain Controller. You may proceed if the ID
      you intend to use exists, or if you wish to use a Local account.

   (If you wish to use a Windows Domain User ID, *make sure it exists*
      and that your computer or device is properly connected to the
      $dom Windows Domain.)

END
      } else {
         $banner=<<END;

   IMPORTANT! - The Windows command: net user /domain  had no output.

   If you intend to use a Windows Domain Account for the Cygwin sshd
      service it is helpful that the FullAuto Installer be able to query
      the $dom Domain Controller. You may proceed if the ID
      you intend to use exists, or if you wish to use a Local account.

   (If you wish to use a Windows Domain User ID, *make sure it exists*
      and that your computer or device is properly connected to the
      $dom Windows Domain.)

END
      } 
      unless ($success_flag) {
         my %_cygservnf=(
            Label => '_cygservnf',
            Item_1 =>  {
                  Text   => "]C[",
                  Convey => [

                     "Use Local ID \'cyg_server\'  ( Local ID will be ".
                     "created\n                 automatically if necessary. ".
                     "Default & Recommended choice. )\n\n",
                     "Use Domain ID \'cyg_server\' ( Domain ID needs to\n".
                     "                 pre-exist and you need to know the ".
                     "password! )",
                     "Enter a different Local User ID.",
                     "Enter a different Domain User ID.",
                     "Use the Local SYSTEM user (least secure)."

                  ],
            },
            Scroll => 1,
            Banner => $banner,
         );
         $selection=Menu(\%_cygservnf);
         chomp $selection;
         exit if $selection eq ']quit[';
         $selection='use_separate_local_login_id_for_sshd'
            if -1<index $selection,'Enter a different Local';
         $selection='use_separate_local_cyg_server_login_id_for_sshd'
            if -1<index $selection,'Use Local ID';
         if (-1<index $selection,'Enter a different Domain') {
            while (1) {
               print "\n\n\n   Please enter the $domain User ID you",
                     "   intend to use for the sshd service: ".
                     "\n\n\n",
                     "   Please TYPE the User ID: ";
               $cyg_id=<STDIN>;
               chomp $cyg_id;
               print "\n\n\n   You entered ==> $cyg_id\n\n".
                     "   is this correct? (Y|N): ";
               my $yn=<STDIN>;
               last if lc($yn) eq 'y' || 'yes';
            }
         }
      } elsif ($cyg_id eq 'cyg_server') {
         my $o=`net user cyg_server 2>&1`;
         if (-1==index $o,'user name could not be found') {
            my %_cygserv=(
   
               Label => '_cygserv',
               Item_1 =>  {
                     Text   => "]C[",
                     Convey => [ "Use Domain ID \'cyg_server\'\n".
                                 '                '.
                                 '( You need to know the password! )',
                                 'Select ID from All Domain ID\'s',
                                 'Use a Local account' ],
               },
               Scroll => 1,
               Banner=> "   The Domain User 'cyg_server' has been located,\n".
                        "   do you wish to use it, or would you rather\n".
                        "   select from all Domain Users, or use a Local\n".
                        "   account for the sshd service?\n\n".
                        "   (If you wish to use a Domain User ID, please\n".
                        "   *make sure it exists* in the current Domain: $dom".
                        "\n   before".
                        " running FullAuto Setup. If you wish to use\n".
                        "   a Local account, FullAuto can use an existing\n".
                        "   one, or create a new one.)",
            );
            $selection=Menu(\%_cygserv);
            chomp $selection;
            exit if $selection eq ']quit[';
            $selection='use_separate_local_login_id_for_sshd'
               if -1<index $selection,'Use a Local';
         } else {
            test_windows_user_rights('cyg_server') if $^O eq 'cygwin';
            $selection='cyg_server'; 
         }         
      } else {
         my %_cygserv=(

            Label => '_cygserv',
            Item_1 =>  {
                  Text   => "]C[",
                  Convey => [ 'Select ID from All Domain ID\'s',
                              'Use a Local account' ],
            },
            Banner=> "   'cyg_server' has *NOT* been located in the $dom ".
                     "Domain.\n".
                     "   If you wish to use the 'cyg_server' id as a Domain".
                     " ID\n".
                     "   for the OpenSSH sshd service on this host: ".
                     $hostname."\n".
                     "   type 'quit', exit FullAuto Setup, create the\n".
                     "   'cyg_server' User in the $dom Domain, and *then*\n".
                     "   run FullAuto Setup again.\n\n",
                     "   Or, would you rather select from all Domain Users,".
                     "   or use a Local account for the sshd service?\n\n".
                     "   (If you wish to use a Local account, FullAuto\n".
                     "    can use an existing one, or create a new one.)",
         );
         $selection=Menu(\%_cygserv);
         chomp($selection);
         exit if $selection eq ']quit[';
         $selection='use_separate_local_login_id_for_sshd'
            if -1<index $selection,'Use a Local';
      }
      if (-1<index $selection, 'All Domain' || !$cyg_id) {
         my %_users=(

            Label => '_users',
            Item_1 =>  {
                           Text   => "]C[",
                           Convey => \@users,
                       },
            Banner=> "   Select the $dom User to Run the sshd Service\n\n".
                     "   Hit <ENTER> or user ARROW keys to scroll\n\n".
                     "   List can be searched by typing  /[string]\n".
                     "   (forward slash key followed by text to search for).", 
         );
         $selection=Menu(\%_users);
         chomp($selection);
         exit if $selection eq ']quit[';
         test_windows_user_rights($selection) if $^O eq 'cygwin';
      } elsif (-1<index $selection, 'Use Domain') {
         test_windows_user_rights('cyg_server') if $^O eq 'cygwin';
         $selection='cyg_server'; 
      }
   }
   return $selection;

}

# Define metadata
if ($^O ne 'MSWin32' && $^O ne 'MSWin64') {

version         $VERSION;
name            'Net-FullAuto';
sign;
author          'Brian M. Kelly <Brian.Kelly@FullAuto.com>';
license         'gpl-3.0';
perl_version    '5.006';

}

require Mozilla::CA;
require Term::Menus;
require Term::ReadKey;
require Term::RawInput;
my $last_known_good_location=
#      "http://download.oracle.com/berkeley-db/db-5.2.28.tar.gz";
      "http://download.oracle.com/berkeley-db/db-6.2.32.tar.gz";

my $process_id='';my $PREFIX='';
$process_id=pop @ARGV if $ARGV[$#ARGV-1]=~/^\d+$/;
my $install_cygwin_without_asking=0;
our $cygwin_berkeley_db_mode=777;
if (exists $ENV{FA_BERKELEY} &&
      (-1<index $ENV{FA_BERKELEY},'Owner Group')) {
   $cygwin_berkeley_db_mode=770;
}
our $mozrepl_file='mozrepl-1.1-fx.xpi';
our $install_firefox_without_asking=0;
our $install_firefox=(exists $ENV{FA_MOZREPL})?$ENV{FA_MOZREPL}:0;
our $install_webapi=(exists $ENV{FA_WEBAPI})?$ENV{FA_WEBAPI}:'';

if (exists $Config{prefix} &&
      $Config{prefix}) {
   $PREFIX=$Config{prefix};
}

foreach my $arg (@ARGV) {
   if ($arg=~/INSTALL_*CYGWIN\s*=\*1/i) {
      $install_cygwin_without_asking=1;
   } elsif ($arg=~/INSTALL_*FIREFOX\s*=\*1/i) {
      $install_firefox_without_asking=1;
   } elsif ($arg=~/-*-PREFIX=/i) {
      $PREFIX=$arg;
      $PREFIX=~s/^-*-[Pp][Rr][Ee][Ff][Ii][Xx]=//;
      $PREFIX=~s/^["']//;
      $PREFIX=~s/["']$//;
   }
}

$PREFIX='' if $PREFIX='/usr';

my $editor='';my $selection='';my $berkeleydb='';
my $fa_sshd_banner=<<'END';

    ___     _ _   _       _                            _       _ ___
   | __|  _| | | /_\ _  _| |_  |      ___ _ _    _____| |_  __| |__ \
   | _| || | | |/ _ \ || |  _/ | \   / _ \ '_|  (_-<_-< ' \/ _` | /_/
   |_| \_,_|_|_/_/ \_\_,_|\__\___/c  \___/_|    /__/__/_||_\__,_|(_)


END
my $sshd_fa_banner=<<'END';

    ___     _ _   _       _                        _          _       _ ___
   | __|  _| | | /_\ _  _| |_  |      __ _ _ _  __| |   _____| |_  __| |__ \
   | _| || | | |/ _ \ || |  _/ | \   / _` | ' \/ _` |  (_-<_-< ' \/ _` | /_/
   |_| \_,_|_|_/_/ \_\_,_|\__\___/c  \__,_|_||_\__,_|  /__/__/_||_\__,_|(_)


   You have selected to install FullAuto. A local ssh Windows service (sshd)
   is *NOT* required for use with FullAuto on this host, but it is a useful
   option. However, an ssh service on Windows is a security "concern" that
   a number of experts advise against. No matter how secure it is, it is an
   additional access point to this host. Carefully consider the risk versus
   the increased utility a ssh service provides for a MS Windows based host.


END
if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {

   my $cygwin_loc=get_cygwin_location();

   if ($cygwin_loc) {

      my %Menu_update_cyg=(

         Label  => 'Menu_update_cyg',
         Item_1 => {

            Text => "Install FullAuto  =>  Will automatically ".
                    "Update installed\n                                 ".
                    "   Cygwin Linux Emulation ".
                    "Layer.\n\n              ( Cygwin ".
                    "is REQUIRED to run FullAuto on Microsoft Windows ) ".
                    "\n\n\n",

         },
         Item_2 => {

            Text => "Install sshd only  =>  Update Base Cygwin and Install".
                    "\n                                     OpenSSH sshd ".
                    "(ssh service for Windows)\n".
                    "\n              ( Allows FullAuto processes on other ".
                    "hosts to connect and\n                ".
                    "interact with this host. FullAuto will NOT be ".
                    "installed ).\n\n",

         },
         Item_3 => {

            Text    => "Do NOT Update Cygwin ".
                       "( FullAuto Install will END ).\n\n",

         },
         Scroll => 1,
         Banner => $fa_sshd_banner,

      );
      if ($install_cygwin_without_asking) {
         $selection='Install';
      } else {
         $selection=Term::Menus::Menu(\%Menu_update_cyg);
         chomp($selection);
         exit if $selection eq ']quit[';
      }
   } else {
      my %Menu_win_to_cyg=(

         Label  => 'Menu_win_to_cyg',
         Item_1 => {

            Text => "Install Fulluto  =>  Will automatically Install or".
                    " Update\n                                   ".
                    "Cygwin Linux Emulation ".
                    "Layer.\n\n              ( Cygwin ".
                    "is REQUIRED to run FullAuto on Microsoft Windows ) ".
                    "\n\n\n",

         },
         Item_2 => {

            Text => "Install sshd only  =>  Install and configure Base Cygwin".
                    " and\n                                     OpenSSH sshd ".
                    "(ssh service for Windows)\n".
                    "\n              ( Allows FullAuto processes on other ".
                    "hosts to connect and\n                ".
                    "interact with this host. FullAuto will NOT be ".
                    "installed ).\n\n",

         },
         Item_3 => {

            Text    => "DO *NOT* Install Cygwin ".
                       "( FullAuto Install will END ).\n\n",

         },
         Scroll => 1,
         Banner => $fa_sshd_banner,

      );
      if ($install_cygwin_without_asking) {
         $selection='Install';
      } else {
         $selection=Term::Menus::Menu(\%Menu_win_to_cyg);
         chomp($selection);
         exit if $selection eq ']quit[';
      }
   }
   if ($selection!~/will END/s) {
      my $sshd_selection='';
      if ($selection!~/Install sshd only/s) {
         my %Menu_win_to_cyg=(

            Label  => 'Menu_win_to_cyg',
            Item_1 => {

               Text => "Do *NOT* Install sshd with FullAuto.\n\n",

            },
            Item_2 => {

               Text => 
                  "Install FullAuto and sshd (ssh service) for Windows.\n\n",

            },
            Scroll => 1,
            Banner => $sshd_fa_banner,

         );
         if ($install_cygwin_without_asking) {
            $sshd_selection='Do *NOT* Install sshd';
         } else {
            $sshd_selection=Term::Menus::Menu(\%Menu_win_to_cyg);
            chomp($sshd_selection);
            $sshd_selection='Do *NOT* Install sshd' if $sshd_selection
               eq 'Do *NOT* Install sshd with FullAuto.';
            exit if $sshd_selection eq ']quit[';
         }

      }

      my $url='http://www.cygwin.com/setup-x86.exe';
      $url='http://www.cygwin.com/setup-x86_64.exe'
         if $^O eq 'MSWin64' || msw64bit();
      if ($CPAN::META->has_usable('LWP')) {
         FA::LWP::UserAgent->config;
         print "Fetching with LWP:\n  $url\n";
         my $Ua;
         eval {
            local $SIG{__DIE__}; # No sigdie handler;
            $Ua = FA::LWP::UserAgent->new(
                  timeout=>300,show_progress=>1)
         };
         if ($@) {
            $CPAN::Frontend->mywarn(
               "ERROR: FA::LWP::UserAgent->new dies with $@\n");
         } else {
            my($var);
            $Ua->proxy('http', $var)
               if $var = $CPAN::Config->{http_proxy} ||
               $ENV{http_proxy};
            $Ua->no_proxy($var)
               if $var = $CPAN::Config->{no_proxy} || $ENV{no_proxy};
         }
         my $req = HTTP::Request->new(GET => $url);
         $req->header('Accept' => 'text/html');
         my $res = $Ua->request($req);
         if ($res->is_success) {
            print " + request successful.\n"
               if $CPAN::DEBUG;
            mkpath($cygwin_root_dir,1) unless -d $cygwin_root_dir;
            unless (-w $cygwin_root_dir) {
               print "\n\n   FATAL ERROR! - The current Cygwin directory: ".
                        "\n\n      ".$cygwin_root_dir."\n\n".
                        "   is not writable. Please change the permissions\n".
                        "   to writable before installing FullAuto.\n";
               print "\n   PRESS ANY KEY TO EXIT SETUP\n\n";
               <STDIN>;
               exit 1;
            }
            if ($^O eq 'MSWin64' || msw64bit()) {
               open(CP,">$cygwin_root_dir\\setup-x86_64.exe") || fa_die($!);
            } else {
               open(CP,">$cygwin_root_dir\\setup-x86.exe") || fa_die($!);
            }
            binmode(CP);
            print CP $res->content;
            my $cyghome=$Ua->get('http://www.cygwin.com');
            if ($^O ne 'cygwin' && $cyghome->is_success) {
               my $content=$cyghome->content;
               my $cygver='';
               ($cygver=$content)=~
                  s/^.*of the Cygwin DLL is ([\d|.|-]). In.*$/$1/s;
               if ($cygver=~/(1.7.11-1)/) {
                  print "\n\n   FATAL ERROR! - The current Cygwin version: $1".
                        "\n   (Base Cygwin cygwin1.dll) at cygwin.com is\n".
                        "   incompatible with FullAuto. Please manually\n".
                        "   download the setup utility from www.cygwin.com,\n".
                        "   and install an\n   older version of Base Cygwin.\n".
                        "   Only then can\n   successfully install FullAuto.\n".
                        "   Optionally, you\n   can also manually install\n".
                        "   Perl when setting up\n   a compatible version of\n".
                        "   Cygwin, and afterwards\n   use the bundled cpan\n".
                        "   utility to install FullAuto\n   You may need to\n".
                        "   contact your Windows System\n   Administrator to\n".
                        "   resolve.\n\n".
                        "   PRESS ANY KEY to Exit Setup\n\n";
                  <STDIN>;
                  exit 1;
               }
            } 
         } elsif ($res->status_line=~/403/) {
            if ($^O eq 'MSWin64' || msw64bit()) { 
               $url='http://www.FullAuto.com/download/setup-x86_64.exe';
            } else {
               $url='http://www.FullAuto.com/download/setup-x86.exe';
            }
            $req = HTTP::Request->new(GET => $url);
            $req->header('Accept' => 'text/html');
            $res = $Ua->request($req);
            if ($res->is_success) {
               print " + request successful.\n"
                  if $CPAN::DEBUG;
               mkpath($cygwin_root_dir,1) unless -d $cygwin_root_dir;
               if ($^O eq 'MSWin64' || msw64bit()) {
                  open(CP,">$cygwin_root_dir\\setup-x86_64.exe") || fa_die($!);
               } else {
                  open(CP,">$cygwin_root_dir\\setup-x86.exe") || fa_die($!);
               }
               binmode(CP);
               print CP $res->content;
            } elsif ($res->status_line=~/403/) {
               $url='http://www.FullAuto.com/download/setup.tar.gz';
               $req = HTTP::Request->new(GET => $url);
               $req->header('Accept' => 'text/html');
               $res = $Ua->request($req);
               if ($res->is_success) {
                  print " + request successful.\n"
                     if $CPAN::DEBUG;
                  open(CP,">$PARdir\\setup.tar.gz") || fa_die($!);
                  binmode(CP);
                  print CP $res->content;
               } else {
                  fa_die($res->status_line);
               }
            } else {
               fa_die($res->status_line);
            }
         } else {
            fa_die($res->status_line);
         }
         close(CP) || fa_die($!);
         if ($^O eq 'MSWin64' || msw64bit()) {
            chmod 0755, "$cygwin_root_dir\\setup-x86_64.exe";
         } else {
            chmod 0755, "$cygwin_root_dir\\setup-x86.exe";
         }
        
         my $mirror_url='http://www.cygwin.com/mirrors.html';
         $req = HTTP::Request->new(GET => $mirror_url);
         $req->header('Accept' => 'text/html');
         $res = $Ua->request($req);
         my $href='';my @urls=();
         $mirror_url='http://cygwin.mirrors.pair.com';
         if ($res->is_success) {
            print " + request successful.\n"
               if $CPAN::DEBUG;
            my $mirrors=$res->content;
            foreach my $href ($mirrors=~/href="(.*?)"/mg) {
               next if -1==index $href,'://';
               next if -1<index $href,'html';
               next if -1==index $href,'http';
               push @urls, $href;
            }
            $mirror_url=$urls[int(rand($#urls))];
         }
         my $setup_cmd='';
         my $drlet=substr($cygwin_root_dir,0,2);
         if ($selection!~/Install sshd only/s) {

            $install_webapi=fa_web_api();

            my $selection='';
            ($selection,$editor)=fa_editor_mswin();

            if ($selection eq 'vim') {
               $selection='';
            } else {
               $selection=",$selection";
            }

            if ($^O eq 'MSWin64' || msw64bit()) {
               $setup_cmd="$drlet & cd \"$cygwin_root_dir\" & "
                      .'setup-x86_64.exe -P gcc-core,perl-libwww-perl,'
                      .'gcc-g++,make,openssh,openssl,openssl-devel,perl,'
                      .'procps-ng,vim,unzip,libmpfr4,figlet,wget,get,'
                      .'db,libdb-devel,ncurses,cron,inetutils,pkg-config,'
                      .'git,libcrypt-devel,perl-LWP-Protocol-https,nano,'
                      .'autobuild,autoconf,automake,libtool,libxml2-devel,'
                      .'libisl15,libcloog-isl4,sqlite3,rpm,cpio,curl'
                      .$selection.' -X -A -q '."-R $cygwin_root_dir "
                      .'-s '.$mirror_url;
            } else {
               $setup_cmd="$drlet & cd \"$cygwin_root_dir\" & "
                      .'setup-x86.exe -P gcc-core,nano,'
                      .'gcc-g++,make,openssh,openssl,openssl-devel,perl,'
                      .'perl-Win32,db4.8,libdb4.8-devel,ncurses,cron,'
                      .'inetutils,procps,vim,unzip,libmpfr4,figlet,git,'
                      .'wget -X -A -q '."-R $cygwin_root_dir "
                      .'-s '.$mirror_url;
            }
         } else {
            if ($^O eq 'MSWin64' || msw64bit()) {
               $setup_cmd="$drlet & cd \"$cygwin_root_dir\" & "
                      .'setup-x86_64.exe -P openssh,ncurses,inetutils,'
                      .'procps-ng,git,vim,nano,libmpfr4,figlet,wget '
                      .'-X -A -q '."-R $cygwin_root_dir ".'-s '.$mirror_url;
            } else {
               $setup_cmd="$drlet & cd \"$cygwin_root_dir\" & "
                      .'setup-x86.exe -P openssh,ncurses,inetutils,'
                      .'procps,vim,nano,libmpfr4,figlet,git,wget '
                      .'-X -A -q '."-R $cygwin_root_dir ".'-s '.$mirror_url;
            }
         }
         
         my $wver=&windows_ver;
         my $account_type='separate';
         my @sshd_password=();
         my $sshd_account='cyg_server';
         my $privl='';
         my $domain_user='';my $domain='';
         if ($wver!~/95|98|ME/ and
               ($sshd_selection ne 'Do *NOT* Install sshd')) {
            my $domain=`net config workstation`;
            $domain=~/^.*Workstation domain\s+(.+)\s*$/m;
            $domain=$1||'';
            $domain=~tr/\0-\37\177-\377//d;
            chomp($domain);
            if ($wver=~/XP|2000|NT/) {
               my $banner="   For $wver, you have a choice of using\n"
                         ."   either the Local SYSTEM user for the\n"
                         ."   REQUIRED sshd (Secure Shell Daemon/Service\n"
                         ."   supplied by OpenSSH) or a separate user\n"
                         ."   account. The Local SYSTEM account is less\n"
                         ."   maintenance and you won't need to manage or\n"
                         ."   remember a separate account and password -\n"
                         ."   BUT IT IS LESS SECURE. Using a separate user\n"
                         ."   account is *HIGHLY* recommended!:";
               my %Menu_select_account_type=(
         
                   Label  => 'Menu_select_account_type',
                   Item_1 => {
        
                      Text => "Use separate user account for sshd service",
         
                   },
                   Item_2 => {

                      Text => "Use the Local SYSTEM user (least secure)",
         
                   },
                   Banner => $banner,
         
               );
               $account_type=Term::Menus::Menu(\%Menu_select_account_type);
               chomp($account_type);
               exit if $account_type eq ']quit[';
               $privl=' --privileged' if -1<index $account_type,'separate';
            }
            $domain_user=&ws_info($domain) unless $wver=~/XP|2000|NT/;
            my $setup_cyg_server=0;
            if ($domain_user eq 'use_separate_local_login_id_for_sshd') {
               $account_type='separate';
               $domain_user='';
            } elsif ($domain_user eq 
                  'use_separate_local_cyg_server_login_id_for_sshd') {
               $account_type='separate';
               $domain_user='';
               $setup_cyg_server=1 if (-1==index `net user`,'cyg_server');
            } elsif ($domain_user eq
                  'Use the Local SYSTEM user (least secure)') {
               $account_type='system';
               $domain_user='';
            }
            if ($domain_user) {
               print "\n\n\n   Please enter the Password for the $domain ",
                     "account $domain_user,\n   and take steps to insure ".
                     "it's security and recoverability\n   ",
                     "(i.e. - store a copy in a SAFE ",
                     "place where you can find\n   it if necessary.)\n\n\n",
                     "   Please TYPE the Password\n   for ",
                     "$domain domain account \'$domain_user\': ";
               Term::ReadKey::ReadMode(2);
               my $pas=<STDIN>;
               $pas=~/^(.*)$/;
               $sshd_password[0]=$1;
               Term::ReadKey::ReadMode(0);
               chomp($sshd_password[0]);
               print "\n\n   Please verify the $domain_user Password: ";
               Term::ReadKey::ReadMode(2);
               $pas=<STDIN>;
               $pas=~/^(.*)$/;
               $sshd_password[1]=$1;
               Term::ReadKey::ReadMode(0);
               chomp($sshd_password[1]);
               if ($sshd_password[0] ne $sshd_password[1]) {
                  @sshd_password=();
                  my $cc=2;
                  while ($cc--) {
                     print "\n\n";
                     print "   Your Password entries do NOT match!\n\n",
                           "   Please carefully type the\n",
                           "   $domain_user Password: ";
                     Term::ReadKey::ReadMode(2);
                     $pas=<STDIN>;
                     $pas=~/^(.*)$/;
                     $sshd_password[0]=$1;
                     Term::ReadKey::ReadMode(0);
                     chomp($sshd_password[0]);
                     print "\n\n   Please verify the $domain_user Password: ";
                     Term::ReadKey::ReadMode(2);
                     $pas=<STDIN>;
                     $pas=~/^(.*)$/;
                     $sshd_password[1]=$1;
                     Term::ReadKey::ReadMode(0);
                     chomp($sshd_password[1]);
                     last if $sshd_password[0] eq $sshd_password[1];
                  }
               }
               if ($sshd_password[0] ne $sshd_password[1]) {
                  print "\n\n";
                  print "FATAL ERROR!: Unable to verify Password entries!\n\n";
                  print "Press any key to exit FullAuto Setup.\n";
                  <STDIN>;exit 1;
               }
               print "\n";
            } elsif (-1<index $account_type,'separate') {
               if (!$setup_cyg_server) {
                  print "\n       Please type the name of the $wver\n",
                        "        user account that will be used by the sshd\n",
                        "        service: ";
                  $sshd_account=<STDIN>;
                  print "\n";
               }
               print "\n\n\n   Now is the time to CAREFULLY select a ",
                     "password for the\n   $sshd_account account, and",
                     " take steps to insure it's security\n   and ",
                     "recoverability (i.e. - store a copy in a SAFE ",
                     "place where\n   you can find it if necessary.)\n\n\n",
                     "   Please TYPE your new Password\n   for ",
                     "account \'$sshd_account\': ";
               Term::ReadKey::ReadMode(2);
               my $pas=<STDIN>;
               $pas=~/^(.*)$/;
               $sshd_password[0]=$1;
               Term::ReadKey::ReadMode(0);
               chomp($sshd_password[0]);
               print "\n\n   Please verify your new Password: ";
               Term::ReadKey::ReadMode(2);
               $pas=<STDIN>;
               $pas=~/^(.*)$/;
               $sshd_password[1]=$1;
               Term::ReadKey::ReadMode(0);
               chomp($sshd_password[1]);
               if ($sshd_password[0] ne $sshd_password[1]) {
                  @sshd_password=();
                  my $cc=2;
                  while ($cc--) {
                     print "\n\n";
                     print "   Your Password entries do NOT match!\n\n",
                           "   Please carefully type your\n",
                           "   new Password: ";
                     Term::ReadKey::ReadMode(2);
                     $pas=<STDIN>;
                     $pas=~/^(.*)$/;
                     $sshd_password[0]=$1;
                     Term::ReadKey::ReadMode(0);
                     chomp($sshd_password[0]);
                     print "\n\n   Please verify your new Password: ";
                     Term::ReadKey::ReadMode(2);
                     $pas=<STDIN>;
                     $pas=~/^(.*)$/;
                     $sshd_password[1]=$1;
                     Term::ReadKey::ReadMode(0);
                     chomp($sshd_password[1]);
                     last if $sshd_password[0] eq $sshd_password[1];
                  }
               }
               if ($sshd_password[0] ne $sshd_password[1]) {
                  print "\n\n";
                  print "FATAL ERROR!: Unable to verify Password entries!\n\n";
                  print "Press any key to exit FullAuto Setup.\n";
                  <STDIN>;exit 1;
               }
            } elsif (-1<index $account_type,'system') {
               $sshd_password[0]='none';
            } else {
               my $netuser=`net user`;
               $netuser=~s/^.*----(.*)The command comp.*$/$1/s;
               $netuser=~s/^\s*//s;
               $netuser=~s/\s*$//s;
               $netuser=~s/\n/         /g;
               my @netuser=split /    \s*/, $netuser;
               @netuser=grep { $_ ne 'sshd' } @netuser;
               my %sshd_account=();
               if (grep { 'cyg_server' eq $_ } @netuser) {
                  my $cs_info=`net user cyg_server`;
                  my $pwls='';my $ll='';
                  ($pwls=$cs_info)
                     =~s/^.*(Password last set\s*.*?(?:PM|AM)).*/$1/s;
                  ($ll=$cs_info)
                     =~s/^.*(Last logon\s*.*?(?:PM|AM)).*/$1/s;
                  %sshd_account=(

                     Label => 'sshd_account',
                     Item_1 => {

                        Text => 'Remove and recreate local \'cyg_server\''.
                                ' account.'.
                                "\n                 ( Recommended )\n\n",
                     },
                     Item_2 => {

                        Text => 'Use the pre-existing local \'cyg_server\''.
                                " account.\n\n",

                     },
                     Item_3 => {

                        Text => 'Use or create a different local account.',

                     },
                     Banner => "\n   Cygwin's sshd service requires a".
                               "\n   dedicated Windows user account.".
                               "\n   A pre-existing local \'cyg_server\' ID ".
                               "\n   was found with the following properies:".
                               "\n\n      $pwls\n      $ll".
                               "\n\n   Please select an action:",


                  );
               }
               my $selection=Menu(\%sshd_account);
               if (-1<index $selection, 'Remove') {
                  my $ndout=`net user sshd /DELETE 2>&1`;
                  my $cgout=`net user cyg_server /DELETE 2>&1`;
               } elsif (-1==index $selection, 'pre-existing') {
                  @netuser=grep { $_ ne 'cyg_server' } @netuser;
                  %sshd_account=(

                     Label => 'sshd_account',
                     Item_1 => {

                        Text => 'Create a new dedicated Windows user account'.
                                "\n                   (You will be prompted)".
                                "\n\n",

                     },
                     Item_2 => {

                        Text => 'Use the pre-existing \']C[\' local account.',
                        Convey => \@netuser,

                     },
                     Banner => "\n   Cygwin's sshd service requires a".
                               "\n   dedicated Windows user account.".
                               "\n   You can select a pre-existing one,".
                               "\n   or elect to use a different one.".
                               "\n\n   Please select an action:",


                  );
                  $selection=Menu(\%sshd_account);
                  chomp($selection);
                  exit if $selection eq ']quit[';
                  if (-1<index $selection,'pre-exist') {
                     $selection=~s/^.*?['](.*?)['].*$/$1/;
                     $sshd_account=$selection;
                  } else {


                  }
               }
# Check if cyg_server exists but is bad
# Then either remove and ask or just ask if cyg_server or other id
            }
            # Let's see if Cygwin remnants remain that could mess
            # up the installation
            my $check_for_orphaned_sshd_service=`sc qc sshd 2>&1`;              
            unless (-1<index $check_for_orphaned_sshd_service,'does not') {
               my $cygpath=~s/^.*H_NAME\s+:\s+(.*exe).*$/$1/s;
               $cygpath=~s/\\/\//g;
               unless (-e $cygpath) {
                  # cygrunsrv does not exist - let's see if its running?
                  my $chkrun=`sc query sshd 2>&1`;
                  if (-1<index $chkrun,'RUNNING') {
                     # Its running - let's stop it
                     my $stopout=`net stop sshd 2>&1`;
                     unless (-1<index $stopout,'stopped suc') {
                        print "FATAL ERROR! - cannot stop sshd: $stopout\n";
                        exit 1;
                     } 
                  }
                  # Now let's delete sshd 
                  my $sc_out=`sc delete sshd 2>&1`;
                  unless (-1<$sc_out,'SUCCESS') {
                     print "FATAL ERROR! - cannot delete sshd: $sc_out\n";
                     exit 1;
                  }
               }
            } check_cygserver();
         } elsif ($sshd_selection eq 'Do *NOT* Install sshd') {
            check_cygserver();
         }

         if ($selection!~/Install sshd only/s) {

            my $p_one="Install with 777 Permissions on FullAuto Files Only (Default)".
                      "\n\n";
            my $p_two="Install with 770 Permissions on FullAuto Files Only ".
                      "(Experimental)\n\n";
            my $p_banner=<<'END';

    ___     _ _   _       _           ___                  _ _
   | __|  _| | | /_\ _  _| |_  |     / __| ___ __ _  _ _ _(_) |_ _  _
   | _| || | | |/ _ \ || |  _/ | \   \__ \/ -_) _| || | '_| |  _| || |
   |_| \_,_|_|_/_/ \_\_,_|\__\___/c  |___/\___\__|\_,_|_| |_|\__|\_, |
                                                                 |__/


   Owner/Group is more secure - but choose this only if security is
   important, and you know how to work with operating system permissions.

   Choose a Permission Setting :


END
            my %Menu_select_permissions=(

               Label  => 'Menu_select_permissions',
               Item_1 => {
                            Text => $p_one,
                         },
               Item_2 => { Text => $p_two },
               Scroll => 1,
               Banner => $p_banner,

            );

            $selection=Term::Menus::Menu(\%Menu_select_permissions);
            chomp($selection);
            exit if $selection eq ']quit[';
            $cygwin_berkeley_db_mode=$selection;

            #&find_windows_firefox() if
            #   (-1==index $install_firefox,'Install') &&
            #   (-1==index $install_firefox,'NOT');

         }

         fa_system($setup_cmd);

         if ($^O eq 'cygwin') {
            my $cygwin_loc=get_cygwin_location();
            my $clo=$cygwin_loc;
            $clo=~s/\\/\\\\/g;
            my $srvcmd='export CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\\\bin\\\\bash -lc ".
                       '"/usr/bin/cygrunsrv -L"';
            my $cygsrvs=`$srvcmd 2>&1`;
            if (($sshd_selection ne 'Do *NOT* Install sshd')
                  && -1==index $cygsrvs,'sshd') {
               if ($domain_user) {
                  fa_system('export CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\\\bin\\\\bash -lc ".
                         '"/usr/bin/mkpasswd -u \"'.$domain_user.'\" '.
                         '-d \"'.$domain.'\" >> /etc/passwd"');
                  fa_system('export CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\\\bin\\\\bash -lc ".
                         '"/usr/bin/mkgroup -d \"'.$domain.'\" '.
                         '-g  \"Domain Users\" '.
                         '>> /etc/group"');
                  $domain_gr_flag=1;
                  $sshd_account=$domain_user;
               }
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/ssh-host-config -y '.
                      '-u \"'.$sshd_account.'\" -w \"'.
                      $sshd_password[0].'\" '.
                      '-c \"ntsec\"'.$privl.'"');
               print "\n   FullAuto Install continues . . . \n\n";
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/ssh-user-config -n"');
               print "\n   FullAuto Install continues . . . \n\n";
            }
            if (-1==index $cygsrvs,'cygserver') {
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/cygserver-config -y"');
            }
            #system('export CYGWIN=nodosfilewarning & '.
            #       "cmd /c $clo\\\\bin\\\\bash -lc ".
            #       '"/usr/bin/cron-config"');
            if (($sshd_selection ne 'Do *NOT* Install sshd')
                  && -1==index $cygsrvs,'sshd') {
               my $netstart="cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"net start sshd 2>&1"';
               my $netout=`$netstart`;
            }
            if (-1==index $cygsrvs,'cygserver') {
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"net start cygserver 2>&1"');
            }
            #system('export CYGWIN=nodosfilewarning & '.
            #       "cmd /c $clo\\\\bin\\\\bash -lc ".
            #       '"net start cron 2>&1"');
         } else {
            my $cygwin_loc=get_cygwin_location();
            my $clo=$cygwin_loc;
            $clo=~s/\\/\\\\/g;
            my $srvcmd='SET CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\\\bin\\\\bash -lc ".
                       '"/usr/bin/cygrunsrv -L 2>&1"';
            my $cygsrvs=`$srvcmd 2>&1`;
            if (-1<index $cygsrvs,'system cannot find') {
               #rmtree([ $cygwin_loc ], 1); 
               my @urls=();my $a=0;my $next_mirror='';
               my @used_mirrors=();
               while (1) {
                  if (-1==$#urls) {
                     $url='http://www.cygwin.com/mirrors.html';
                     $req = HTTP::Request->new(GET => $url);
                     $req->header('Accept' => 'text/html');
                     $res = $Ua->request($req);
                     my $href='';
                     if ($res->is_success) {
                        print " + request successful.\n"
                           if $CPAN::DEBUG;
                        my $mirrors=$res->content;
                        foreach my $href ($mirrors=~/href="(.*?)"/mg) {
                           next if -1==index $href,'://';
                           next if -1<index $href,'html';
                           next if -1==index $href,'http';
                           next if -1<index $href,$mirror_url;
                           push @urls, $href;
                        }
                     }
                  }
                  $a++;
                  $next_mirror=$urls[int(rand($#urls))];
                  $setup_cmd=~s/-s .*$/-s $next_mirror/; 
                  fa_system($setup_cmd);
                  my $cygwin_loc=get_cygwin_location();
                  my $clo=$cygwin_loc;
                  $clo=~s/\\/\\\\/g;
                  my $srvcmd='SET CYGWIN=nodosfilewarning & '.
                             "cmd /c $clo\\\\bin\\\\bash -lc ".
                             '"/usr/bin/cygrunsrv -L 2>&1"';
                  my $cygsrvs=`$srvcmd 2>&1`;
                  if (-1<index $cygsrvs,'system cannot find') {
                     push @used_mirrors,$next_mirror;
                     #rmtree([ $cygwin_loc ], 1) if $a<11;
                     next if $a<11;
                     my $usedmirrors=join "\n   ",@used_mirrors;
                     $usedmirrors=~s/\s+$//s;
                     print "\n\n".
                        "   FATAL ERROR! - Cannot install Cygwin\n".
                        "   There were $a attempts from $a different\n\n".
                        "   Cygwin mirror sites:\n\n".
                        "   $mirror_url\n".
                        "   $usedmirrors\n\n".
                        "   *PLEASE* TRY AGAIN!\n\n".
                        "   PRESS ANY KEY to Exit Setup\n\n";
                     <STDIN>;
                     exit 1;
                  } else {
                     if (-1==index $cygsrvs,'cygserver') {
                        fa_system('export CYGWIN=nodosfilewarning & '.
                               "cmd /c $clo\\\\bin\\\\bash -lc ".
                               '"/usr/bin/cygserver-config -y"');
                     }
                     last
                  }
               }
            } elsif (($sshd_selection ne 'Do *NOT* Install sshd')
                  && -1==index $cygsrvs,'sshd') {
               if ($domain_user) {
                  fa_system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\bin\\bash -lc ".
                         '"/usr/bin/mkpasswd -u \"'.$domain_user.'\" '.
                         '-d \"'.$domain.'\" >> /etc/passwd"');
                  unless ($domain_gr_flag) {
                     fa_system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\bin\\bash -lc ".
                         '"/usr/bin/mkgroup -d \"'.$domain.'\" '.
                         '-g  \"Domain Users\" '.
                         '>> /etc/group"');
                     $domain_gr_flag=1;
                  }
                  $sshd_account=$domain_user;
               }
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/ssh-host-config -y '.
                      '-u \"'.$sshd_account.'\" -w \"'
                      .$sshd_password[0].'\" '.
                      '-c \"ntsec\"'.$privl.'"');
               print "\n   FullAuto Install continues . . . \n\n";
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/ssh-user-config -n"');
               print "\n   FullAuto Install continues . . . \n\n";
            }
            if (-1==index $cygsrvs,'cygserver') {
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/cygserver-config -y"');
            }
            #system('SET CYGWIN=nodosfilewarning & '.
            #       "cmd /c $cygwin_loc\\bin\\bash -lc ".
            #       '"/usr/bin/cron-config"');
            if (0<length $cygsrvs) {
               if ($sshd_selection ne 'Do *NOT* Install sshd') {
                  fa_system('SET CYGWIN=nodosfilewarning & '.
                       "cmd /c $cygwin_loc\\bin\\bash -lc ".
                       '"net stop sshd 2>&1"');
               }
               fa_system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\bash -lc ".
                    '"net stop cygserver 2>&1"');
               fa_system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\dash -lc ".
                    '"/bin/rebaseall -v"');
               if ($sshd_selection ne 'Do *NOT* Install sshd') {
                  my $netstart='SET CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\bin\\bash -lc ".
                       '"net start sshd 2>&1"';
                  my $netout=`$netstart`;
                  if (-1<index $netout,'System error') {
                     my $netdel='SET CYGWIN=nodosfilewarning & '.
                        "cmd /c $clo\\bin\\bash -lc ".
                        '"net user sshd /DELETE 2>&1"';
                     my $ndout=`$netdel`;
                     my $cygdel='SET CYGWIN=nodosfilewarning & '.
                        "cmd /c $clo\\bin\\bash -lc ".
                        '"net user cyg_server /DELETE 2>&1"';
                     my $cgout=`$cygdel`;
                     my $netrm='SET CYGWIN=nodosfilewarning & '.
                        "cmd /c $clo\\bin\\bash -lc ".
                        '"/usr/bin/cygrunsrv -R sshd 2>&1"';
                     my $rmout=`$netrm`;
                     if ($domain_user) {
                        fa_system('SET CYGWIN=nodosfilewarning & '.
                           "cmd /c $clo\\bin\\bash -lc ".
                           '"/usr/bin/mkpasswd -u \"'.$domain_user.'\" '.
                           '-d \"'.$domain.'\" >> /etc/passwd"');
                        unless ($domain_gr_flag) {
                           fa_system('SET CYGWIN=nodosfilewarning & '.
                              "cmd /c $clo\\bin\\bash -lc ".
                              '"/usr/bin/mkgroup -d \"'.$domain.'\" '.
                              '-g  \"Domain Users\" '.
                              '>> /etc/group"');
                           $domain_gr_flag=1;
                        }
                     }
                     fa_system('SET CYGWIN=nodosfilewarning & '.
                            "cmd /c $cygwin_loc\\bin\\bash -lc ".
                            '"/usr/bin/ssh-host-config -y '.
                            '-u \"'.$sshd_account.'\" -w \"'.
                            $sshd_password[0].'\" '.
                            '-c \"ntsec\"'.$privl.'"');
                     print "\n   FullAuto Install continues . . . \n\n";
                     fa_system('SET CYGWIN=nodosfilewarning & '.
                            "cmd /c $cygwin_loc\\bin\\bash -lc ".
                            '"/usr/bin/ssh-user-config -n"');
                     print "\n   FullAuto Install continues . . . \n\n";
                     my $net_start='SET CYGWIN=nodosfilewarning & '.
                           "cmd /c $clo\\\\bin\\\\bash -lc ".
                           '"net start sshd 2>&1"';
                     my $netot=`$net_start`;
                  }
               }
               fa_system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\bash -lc ".
                    '"net start cygserver 2>&1"');
            }
            if (($sshd_selection ne 'Do *NOT* Install sshd')
                 && -1==index $cygsrvs,'sshd') {
               my $nettstart='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"net start sshd 2>&1"';
               my $netut=`$nettstart`;
               if (-1<index $netut,'System error') {
                  my $netdel='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"net user sshd /DELETE 2>&1"';
                  my $ndout=`$netdel`;
                  my $netrm='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"/usr/bin/cygrunsrv -R sshd 2>&1"';
                  my $rmout=`$netrm`;
                  fa_system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $cygwin_loc\\bin\\bash -lc ".
                         '"/usr/bin/ssh-host-config -y '.
                         '-u \"'.$sshd_account.'\" -w \"'.
                         $sshd_password[0].'\" '.
                         '-c \"ntsec\"'.$privl.'"');
                  print "\n   FullAuto Install continues . . . \n\n";
                  fa_system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $cygwin_loc\\bin\\bash -lc ".
                         '"/usr/bin/ssh-user-config -n"');
                  print "\n   FullAuto Install continues . . . \n\n";
                  my $net_start='SET CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\\\bin\\\\bash -lc ".
                       '"net start sshd 2>&1"';
                  my $netot=`$net_start`;
               }
            }
            if (-1==index $cygsrvs,'cygserver') {
               fa_system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\bash -lc ".
                    '"net start cygserver 2>&1"');
            }
            #system('SET CYGWIN=nodosfilewarning & '.
            #       "cmd /c $cygwin_loc\\bin\\bash -lc ".
            #       '"net start cron 2>&1"');
         }
         if ($selection!~/Install sshd only/) {
            my $cygwin_loc=get_cygwin_location();
            my $clo=$cygwin_loc;
            $clo=~s/\\/\\\\/g;
            my $incpath=$INC[0];
            $incpath=~s/\\/\//g;
            if ($^O eq 'cygwin') {
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"export PERL_MM_USE_DEFAULT=1;'.
                      'echo y | /usr/bin/perl -e \"eval { require '.
                      'Locale::Maketext::Lexicon;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Locale::Maketext::Lexicon\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"echo y | /usr/bin/perl -e \"eval { require IO::Pty;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\',\'IO::Pty\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"echo y | /usr/bin/perl -e \"eval { require IO::Tee;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\',\'IO::Tee\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"echo y | /usr/bin/perl -e \"eval { require YAML;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\',\'YAML\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"echo y | /usr/bin/perl -e \"eval { require '.
                      'Mo::builder;1 } or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Mo::builder\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require HTML::Tagset;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'HTML::Tagset\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require HTML::Parser;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'HTML::Parser\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require URI;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'URI\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval {require ExtUtils::Depends;1}'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'ExtUtils::Depends\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Task::Weaken;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Task::Weaken\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Digest::MD5;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Digest::MD5\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require B::Utils;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'B::Utils\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Algorithm::Diff;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Algorithm::Diff\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Data::Dump::Streamer;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Data::Dump::Streamer\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Encode::compat;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Encode::compat\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Win32::API;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Win32::API\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Win32::DriveInfo;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Win32::DriveInfo\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require JSON::XS;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'JSON::XS\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require JSON;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'JSON\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Term::ReadKey;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Term::ReadKey\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Term::RawInput;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Term::RawInput\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Term::Menus;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Term::Menus\')}\""');
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Mozilla::CA;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Mozilla::CA\')}\""');
               my $par_dir='SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/cygpath -lm \"'.$PARdir.'\""';
               my $pardir=`$par_dir`;
               chomp($pardir);my $post_install='';
               if (-1<index $install_webapi,'Web API') {
                  $post_install=";fa --log --iset-local".
                     " \\\"FullAuto Proxy Chaining ^^^& RESTful Access\\\"";
               } else { $post_install=";fa --new-user" }
               fa_system('export CYGWIN=nodosfilewarning & '.
                      "start cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"export PERL_MM_USE_DEFAULT=1;'.
                      'export FA_EDITOR=\\"'.$editor.'\\";'.
                      'export FA_WEBAPI=\\"'.$install_webapi.'\\";'.
                      'export FA_BERKELEY=\\"'.
                         $cygwin_berkeley_db_mode.'\\";'.
                      'export FA_MOZREPL=\\"'.$install_firefox.'\\";'.
                      'export PARdir=\\"'.$pardir.'\\";'.
                      '/usr/bin/echo y|/usr/bin/cpan -i REEDFISH/'.
                      "Net-FullAuto-$VERSION.tar.gz$post_install\"");
            } else {
               # http://stackoverflow.com/questions/3462058/how-do-i-automate-cpan-configuration
               my $build_dir='SET CYGWIN=nodosfilewarning & '.
                     "cmd /c $clo\\\\bin\\\\bash -lc ".
                     '"echo y | /usr/bin/perl -e \"require CPAN;'.
                     'require CPAN::FirstTime;'.
                     '^^^*{CPAN::FirstTime::_using_sudo} = sub { return 1 };'.
                     "CPAN::FirstTime::init(\'$Config{privlib}\');".
                     'CPAN::HandleConfig-^^^>load;'.
                     'print \$CPAN::Config-^^^>{build_dir}\" 2>&1"';
               $build_dir=`$build_dir`;
               if ($build_dir=~/^\s*$|Can\'t locate/s) {
                  my $rmdir='SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e '.
                      '\"foreach my \$f (@INC) { my \$e=\$f;'.
                      'if (-e \$e.\'/CPAN/Config.pm\') {'.
                      'rm -f \$e.\'/CPAN/Config.pm\';'.
                      'rm -f \$e.\'/CPAN/Config.pm~\';'.
                      'last}print \'done\'}\" 2>&1"';
                  my $rmd=`$rmdir`;
                  fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/echo y | /usr/bin/cpan"');
               }
               $build_dir=~s/^.*\n(.*)$/$1/s;
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"export PERL_MM_USE_DEFAULT=1;'.
                      '/usr/bin/perl -e \"eval { require '.
                      'Locale::Maketext::Lexicon;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Locale::Maketext::Lexicon\')}\""');
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require IO::Pty;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\',\'IO::Pty\')}\""');
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require IO::Tee;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\',\'IO::Tee\')}\""');
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require YAML;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\',\'YAML\')}\""');
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Mo::builder;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Mo::builder\')}\""');
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Win32::OLE;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'get\',\'Win32::OLE\')}\""');
               my $oledir='SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"/usr/bin/perl -e '.
                      '\"opendir(DIR,\''.$build_dir.'\') or die \$!;'.
                      'my\$t=0;my\$n=\'\';my\$f=\'\';my \$e;'.
                      'while(\$e=readdir(DIR)){'.
                      'next if \$e eq \'.\';'.
                      'next if \$e eq \'..\';'.
                      'next if \$e!~/^Win32-OLE/;'.
                      'next if substr(\$e,-3) eq \'yml\';'.
                      '\$f=\''.$build_dir.'\'.\'/\'.\$e;'.
                      'my \$a=(stat(\$f))[9];'.
                      'my \$d=time() - \$a;'.
                      'if(\$t==0 and \$e=~/^Win32-OLE/){'.
                      '\$t=\$d;\$n=\$f;}if(\$d^^^<\$t){'.
                      '\$t=\$d;\$n=\$f;}}\$n=\$f if !\$n and \$f;'.
                      'print \$f\""';
               my $oledir=`$oledir`;
               $oledir=~s/\s*$//s;
               $oledir=~s/^\s*//s;
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"cd \"'.$oledir.'\";/usr/bin/sed -i '.
                      '\'s/stricmp/strcasecmp/\' OLE.xs;"');
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"cd \"'.$oledir.'\";/usr/bin/perl Makefile.PL;"');
               fa_system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"cd \"'.$oledir.'\";/usr/bin/make install;"');
               my $par_dir='SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"/usr/bin/cygpath -lm \"'.$PARdir.'\""';
               my $pardir=`$par_dir`;
               chomp($pardir);my $post_install='';
               if (-1<index $install_webapi,'Web API') {
                  $post_install=";fa --log --iset-local".
                     " \\\"FullAuto Proxy Chaining ^^^& RESTful Access\\\"";
               } else { $post_install=";fa --new-user" }
               fa_system('set CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\bin\\bash -lc ".
                      '"export PERL_MM_USE_DEFAULT=1;'.
                      'export FA_EDITOR=\\"'.$editor.'\\";'.
                      'export FA_WEBAPI=\\"'.$install_webapi.'\\";'.
                      'export FA_BERKELEY=\\"'.
                         $cygwin_berkeley_db_mode.'\\";'.
                      'export FA_MOZREPL=\\"'.$install_firefox.'\\";'.
                      'export PARdir=\\"'.$pardir.'\\";'.
                      '/usr/bin/echo y|/usr/bin/cpan -i REEDFISH/'.
                      "Net-FullAuto-$VERSION.tar.gz$post_install\"");
            }
         }
         if ($selection!~/Install sshd only/) {
            &install_firefox() if -1<index $install_firefox,
               'Install';
            print "\n\n   FullAuto Installation has completed",
                  "\n\n   Thank you!",
                  "\n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@FullAuto.com.\n\n";
         } else {
            print "\n\n   Cygwin sshd Installation has completed",
                  "\n\n   Thank you!",
                  "\n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@FullAuto.com.\n\n";
         }
         if (exists $ENV{PAR_TEMP}) {
            print "   Press ANY key to exit.\n\n";<STDIN>;
         }
         exit 0;
      }
   } elsif ($process_id) {
      exit;
   }
   my $die=<<'END';

       FATAL ERROR! : Cygwin Linux Emulation Layer
                      is required to use FullAuto
                      on Windows - goto www.cygwin.com.

           Be sure to install the following programs in
           addition to the base package:

           inetutils and openssh [as provided by Cygwin]
           perl [as provided by Cygwin] (*NOT* CPAN)
           perl-Win32 [as provided by Cygwin] (*NOT* CPAN)
           ncurses, cron, and procps-ng [as provided by Cygwin]
           gcc-core and gcc-g++ [as provided by Cygwin]
           Oracle Berkeley DB [as provided by Cygwin or Oracle]

           **IMPORTANT** - the FullAuto install, either manual
           or via CPAN, must be run *inside* a Cygwin bash shell
           when installing FullAuto on Microsoft Windows.

END
   fa_die($die);
}

unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") {
   my @editors=();
   my $banner="\n   ".
           "*** THIS SCREEN WILL TIMEOUT IN 2 MINUTES ***\n\n".
           "   In order is use the integrated edit features\n".
           "   you will need to choose an editor.\n\n".
           "   ( '>' points to default selection )\n\n";
   unless ($editor) {
      if ($^O eq 'cygwin') {
         if (exists $ENV{FA_EDITOR} and $ENV{FA_EDITOR}) {
            $editor=$ENV{FA_EDITOR};
         } else {
            my $tp='';
            my $mount=`/bin/mount -p`;
            $mount=~s/^.*(\/\S+).*$/$1/s;
            unless ($tp=&fa_find_editor('TextPad.exe')) {
               my $sysdr=`cmd /c echo %SystemDrive%`;
               $sysdr=~s/^\s*(.*)\s*$/$1/s;
               my $let=substr($sysdr,0,1);
               my $lt=lc($let);
               if (-e $mount."/$lt/Program Files/TextPad 5/TextPad.exe") {
                  $tp='default';
               }
            }
            if ($tp) {
               push @editors, 'TextPad (Will not work from remote ssh)';
            }
            my $sysdr=`cmd /c echo %SystemDrive%`;
            $sysdr=~s/^\s*(.*)\s*$/$1/s;
            my $let=substr($sysdr,0,1);
            my $lt=lc($let);
            if (-e $mount.
                  "/$lt/Program Files/Windows NT/Accessories/wordpad.exe") {
               unshift @editors,
                  'Microsoft WordPad (Will not work from remote ssh)';
            }
            if (-e '/bin/nano.exe') {
               unshift @editors, 'nano (Recommended for Beginners)';
            }
            if ((-e '/bin/vim.exe') ||
                  (-e '/bin/vim-nox.exe')) {
               unshift @editors, 'vim';
            }
            if ((-e '/bin/emacs.exe') ||
                  (-e '/bin/emacs-nox.exe')) {
               push @editors, 'emacs';
            }
            if (-e '/bin/joe.exe') {
               push @editors, 'joe';
            }
            my %Menu_select_editor=(

                  Label  => 'Menu_select_editor',
                  Item_1 => {

                     Text    => "]C[",
                     Convey  => \@editors,

                  },
                  Scroll => 1,
                  Banner => $banner,

            );
            {
               local $SIG{__DIE__}; # No sigdie handler
               eval {
                  local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
                  alarm 120;
                  $selection=Term::Menus::Menu(\%Menu_select_editor);
                  alarm 0;
               };
               if ($@) {
                  $selection=$editors[0];
               } else {
                  chomp($selection);
                  exit if $selection eq ']quit[';
                  if ($selection=~/TextPad/) {
                     if ($tp eq 'default') {
                        my $sysdr=`cmd /c echo %SystemDrive%`;
                        $sysdr=~s/^\s*(.*)\s*$/$1/s;
                        my $let=substr($sysdr,0,1);
                        my $lt=lc($let);
                        $editor=$mount.
                           "/$lt/Program Files/TextPad 5/TextPad.exe";
                     } else {
                        $tp=~s/\\/\//g;
                        $tp=~s/^([A-Za-z]):(.*)/$1$2/;
                        $editor="$mount/$tp";
                     }
                  } elsif ($selection=~s/(wordpad)/$1/i) {
                     $editor=$mount.
                        "/$lt/Program Files/Windows NT/Accessories/wordpad.exe";
                  } elsif ($selection=~s/(vim)/$1/i) {
                     if (-e '/bin/vim-nox.exe') {
                        $editor='/bin/vim-nox.exe';
                     } else {
                        $editor='/bin/vim.exe';
                     }
                  } elsif ($selection=~s/(emacs)/$1/) {
                     if (-e '/bin/emacs-nox.exe') {
                        $editor='/bin/emacs-nox.exe';
                     } else {
                        $editor='/bin/emacs.exe';
                     }
                  } elsif ($selection=~s/(joe)/$1/) {
                     $editor='/bin/joe.exe';
                  } elsif ($selection=~s/(nano)/$1/) {
                     $editor='/bin/nano.exe';
                  }
                  exit if $selection eq ']quit[';
               }
            };
         }
      } else {
         if ((-e '/usr/bin/vi') || (-e '/bin/vi')) {
            push @editors, 'vi';   
         }
         if (-e '/usr/bin/emacs') {
            push @editors, 'emacs';
         }
         if (1<$#editors) {
            my %Menu_select_editor=(

               Label  => 'Menu_select_editor',
               Item_1 => {

                  Text    => "]C[",
                  Convey  => \@editors,

               },
               Scroll => 1,
               Banner => $banner,

            );
            $selection=Term::Menus::Menu(\%Menu_select_editor);
            chomp($selection);
            exit if $selection eq ']quit[';
            if ($selection=~s/(vi)/$1/) {
               if (-e '/usr/bin/vi') {
                  $editor='/usr/bin/vi';
               } else {
                  $editor='/bin/vi';
               }
            } elsif ($selection=~s/(emacs)/$1/) {
               $editor='/usr/bin/emacs';
            }
         } elsif (1==$#editors) {
            $editor=$editors[0];
         } else {
            $editor='';
         }
      }
   }
} else {
   chmod 0755, $Config{installsitelib}."/Net/FullAuto/Distro";
   chmod 0755, $Config{installsitelib}."/Net/FullAuto/Cloud";
   chmod 0755, $Config{installsitelib}."/Net/FullAuto/ISets";
}

#&find_windows_firefox() if $^O eq 'cygwin' &&
#   ((-1==index $install_firefox,'Install') &&
#   (-1==index $install_firefox,'NOT'));

#if ($^O eq 'cygwin' && !check_for_compiler()) {
if ($^O eq 'cygwin' && !can_cc()) {
   my $uname=`/bin/uname`;
   my $stup='setup-x86.exe';
   $stup='setup-x86_64.exe' if $uname=~/WOW64/ || msw64bit();
   my $die="\n       FATAL ERROR! : The Gnu C Compiler 'gcc': gcc-core".
           "\n                      & gcc-g++ as provided by Cygwin".
           "\n                      is required to install FullAuto".
           "\n                      on Windows.".
           "\n(Hint: Run Cygwin $stup and install 'gcc-core' ".
           "and 'gcc-g++' under the Category 'Devel' ).".
           "\n\n";
   fa_die($die);
} 

if ($^O eq 'cygwin' && !(can_run('/bin/ssh') || can_run('/bin/telnet'))) {
   my $timeout=120;my $a='';
   {
      local $SIG{__DIE__}; # No sigdie handler
      eval {
         local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
         alarm $timeout;
         my $uname=`/bin/uname`;
         my $stup='setup-x86.exe';
         $stup='setup-x86_64.exe' if $uname=~/i686/ || msw64bit();
         print "\n       *** THIS SCREEN WILL TIMEOUT IN 2 MINUTES ***\n". 
               "\n       WARNING! : The Secure Shell - 'ssh'".
               "\n                  and/or 'telnet' (via inetutils)".
               "\n                  as provided by Cygwin".
               "\n                  is required to install FullAuto".
               "\n                  on Windows.".
               "\n(Hint: Run Cygwin $stup and install OpenSSH ".
               "under the Category 'Net' ).".
               "\n\n";
         print "Press <ENTER> if you wish to continue, ",
               "or 'N' to quit . . . [Y] ";
         $a=<STDIN>;
         alarm 0;
      };
      if ($@) {
         # timed out
         exit 1;
      } elsif ($a=~/^[Nn]$/s) {
         exit;
      } alarm 0;
   };
}
if (!can_run('make') && !(($^O eq 'cygwin') && (-e "/usr/bin/make"))) {
   my $die="\n       FATAL ERROR! : Cannot locate 'make'. This program ".
           "\n                      is required to install FullAuto".
           "\n                      (Hint: goto www.gnu.org for gnumake).".
           "\n\n";
   fa_die($die);
}
my $greppath='';
if (-e "/bin/grep") {
   $greppath="/bin/";
} elsif (-e "/usr/bin/grep") {
   $greppath="/usr/bin/";
} elsif (-e "/usr/local/bin/grep") {
   $greppath="/usr/local/bin/";
}
my $get_BerkeleyDB=0;
eval {
   local $SIG{__DIE__}; # No sigdie handler
   require BerkeleyDB;
};
$get_BerkeleyDB=1 if $@;
my $cpan_error='';
eval {
   local $SIG{__DIE__}; # No sigdie handler
   require CPAN::Mini;
   import CPAN::Mini;
};
if (!$@ && grep { /-*add[-_]?dependencies/i } @ARGV) {
   my $distribution = CPAN::Shell->expand(
         "Module",'BerkeleyDB'
      )->distribution()->pretty_id();
   my $let=unpack('a1',$distribution);
   my $lett=unpack('a2',$distribution);
   my $minicpan=CPAN::Mini->new(

      #remote => "http://www.cpan.org",
      remote => "http://www.perl.com/CPAN",
      local  => cwd()."/dependencies/CPAN",
      log_level => 'debug',
      exact_mirror => 1,

   );
   $minicpan->mirror_file(
      "authors/id/$let/$lett/$distribution");
}
if ($get_BerkeleyDB && $^O ne 'cygwin') {
   # Let's find if Berkeley DB is already on the system
   my $findpath='';
   if (-e "/bin/find") {
      $findpath="/bin/";
   } elsif (-e "/usr/bin/find") {
      $findpath="/usr/bin/";
   } elsif (-e "/usr/local/bin/find") {
      $findpath="/usr/local/bin/";
   }
   my $xargspath='';
   if (-e "/bin/xargs") {
      $xargspath="/bin/";
   } elsif (-e "/usr/bin/xargs") {
      $xargspath="/usr/bin/";
   } elsif (-e "/usr/local/bin/xargs") {
      $xargspath="/usr/local/bin/";
   }
   if ($findpath && $xargspath && $greppath) {
      my @output=();
      my $testgrep =`${greppath}grep -H 2>&1`;
      my $testgrep2=`${greppath}grep 2>&1`;
      my $grepopt='';
      if ((-1==index $testgrep,'illegal option')
            && (-1==index $testgrep2,'-insvxbhwyu')) {
         $grepopt='-H ';
      }
      my $testfind =`find -help 2>&1`;
      my $maxdepth=(-1<index $testfind,'[-P]')?
            " -maxdepth 4":'';
      my $find_cmd1="${findpath}find ";
      my $find_cmd2="$maxdepth -name \'*.h\' ".
                   "| ${xargspath}xargs ${greppath}grep ".
                   "${grepopt}DB_VERSION_STRING";
      print "\nSearching for latest verison of Berkeley DB.\n".
            "This may take up to five minutes ...\n\n";
      FE: foreach my $dir ('/usr/','/opt/',(getpwuid $>)[7].'/') {
         next if unpack('a1',$dir) eq '.';
         next unless -d $dir;
         opendir(DIR, $dir) or fa_die($!);
         while (my $file = readdir(DIR) ) {
            next if ($file eq "." or $file eq ".." or $file eq "doc" or
                     $file eq "X11R6" or $file eq "docs" or
                     $file eq "man" or $file eq "ssl" or
                     $file eq "license" or $file eq "logfile" or
                     $file eq "bin" or ($^O eq 'cygwin' &&
                     ($file eq "Application Data" or
                      $file eq "Favorites" or $file eq
                      "Local Settings" or $file eq "Recent" or
                      $file eq "Start Menu" or $file eq "SendTo" or
                      $file eq "NetHood" or $file eq "PrintHood")));
            if (-d $dir.$file) {
               print "Searching $dir$file ...\n";
               my @subout=`$find_cmd1\"$dir$file\"$find_cmd2`;      
               push @output, @subout;
            }
            last FE if $dir.$file eq "/usr/local";
         }
      }
      my @vers=();my %verhash=(); 
      if (-1<$#output) {
         foreach my $version (@output) {
            next if (-1<index $version, $CPAN::Config->{cpan_home}) || 
                    (-1<index $version, 'Net-FullAuto-') ||
                    $version!~/db.h:.*DB_VERSION_STRING/;
            my @fileparts=split 'db.h:', $version;
            $fileparts[1]=~s/^.*DB (\d+[^:]+):.*\s*$/$1/s;
            $verhash{$fileparts[1]}=$fileparts[0]; 
         }
      }
      my $header_to_use='';my $ver='';
      foreach my $vr (reverse sort keys %verhash) {
         $header_to_use=$verhash{$vr};
         $vr=~/^((^\d+[.]\d+)[.]?\d*).*$/;
         $vr=$1;$ver=$2;
         chomp($vr);chomp($ver);
         my $find_cmd="${findpath}find /usr -name \"libdb-".$ver.".a\"";
         my @lib=`$find_cmd`;
         chomp($lib[0]);$berkeleydb=$lib[0];last;
      }
      my $major_minor_ver=substr($ver,0,(rindex $ver,'.'));
      $major_minor_ver=$ver if -1==index $major_minor_ver,'.';
      if ($^O eq 'cygwin' && !(grep { /build_berkeleydb/i } @ARGV)) {
         if ($berkeleydb && $major_minor_ver>=4.5) {
            $berkeleydb=~s/^(.*)\/.*$/$1/;
            $ENV{'BERKELEYDB_INCLUDE'}=$header_to_use;
            $ENV{'BERKELEYDB_LIB'}=$berkeleydb;
            $ENV{'BERKELEYDB_NAME'}="-ldb-$ver";
            $ENV{'DB_FILE_INCLUDE'}=$header_to_use;
            $ENV{'DB_FILE_LIB'}=$berkeleydb;
            $ENV{'DB_FILE_NAME'}="-ldb-$ver";
            $ENV{'LD_LIBRARY_PATH'}=$berkeleydb;
            $ENV{'LD_RUN_PATH'}=$ENV{'LD_LIBRARY_PATH'};
         } else {
            my $uname=`/bin/uname`;
            my $uname_all=`/bin/uname -a`;
            $uname_all.=$uname;
            my $dbdev="libdb${major_minor_ver}-devel";
            $dbdev='libdb-devel' if $uname=~/WOW64|x86_64/;
            print "\n\n   FATAL ERROR!: The \'$dbdev\' package is".
                  " missing from your Cygwin installation.\n".
                  "\n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@FullAuto.com.",
                  "\n\n   Press ANY key to exit.\n\n";<STDIN>;
                  exit 1;
         }
      } elsif ($ENV{AUTOMATED_TESTING} ||
            ($berkeleydb && $major_minor_ver>=5.1)) {
         $berkeleydb=~s/^(.*)\/.*$/$1/;
         $ENV{'BERKELEYDB_INCLUDE'}=$header_to_use;
         $ENV{'BERKELEYDB_LIB'}=$berkeleydb;
         $ENV{'BERKELEYDB_NAME'}="-ldb-$ver";
         $ENV{'DB_FILE_INCLUDE'}=$header_to_use;
         $ENV{'DB_FILE_LIB'}=$berkeleydb;
         $ENV{'DB_FILE_NAME'}="-ldb-$ver";
         $ENV{'LD_LIBRARY_PATH'}=$berkeleydb;
         $ENV{'LD_RUN_PATH'}=$ENV{'LD_LIBRARY_PATH'};
      } else {
         if (-e "dependencies/BerkeleyDB" && !(grep {
               /(?:use[-_]?)?internet|online|connect_to_internet_ok/i
               } @ARGV)) {
            cpan_gunzip_and_untar();
            my $dir=&cwd.'/dependencies/BerkeleyDB';
            opendir(DIR,$dir);
            my @files = readdir(DIR);
            closedir(DIR);
            my $file='';my $filename='';
            foreach my $f (@files) {
               next if $f eq '.';
               next if $f eq '..';
               if (-1==index $f,'.md5') {
                  $file=$f;
                  last;
               }
            }
            my $filenm=$file;
            $file=~s/.tar.gz$//;
            $filename="${file}_${$}.tar.gz";
            File::Copy::copy("$dir/$filenm",&cwd."/$filename");
            my $so=fa_system($CPAN::Config->{gzip}." -d $filename");
            if ($so==-1) {
               fa_die("Cannot gunzip $filename: $!\n");
            }
            $filename=~s/\.gz$//;
            print "***** Untar4: ",
               $CPAN::Config->{tar}," xvf $filename\n";
            fa_system($CPAN::Config->{tar}." xvf $filename"); 
            $filename=~/^(.*)_(\d+).tar$/;
            $filename=$1;
            my $uniq=$2;
            File::Copy::move("$filename.NC","$filename.NC_$uniq");
            my $ver=$filenm;
            $ver=~s/_.*$//;
            $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
            my $pre="/usr/local/BerkeleyDB.$ver";
            $pre=$PREFIX."BerkeleyDB$ver" if $PREFIX;
            build_berkeleydb($filename,$uniq,$pre,$PREFIX,'');
         } else {
            download_berkeleydb();
         }
         unless (exists $ENV{'BERKELEYDB_INCLUDE'} &&
               $ENV{'BERKELEYDB_INCLUDE'}) {
            my $BerkDownload='https://www.oracle.com/technetwork/database/'.
                             'database-technologies/berkeleydb/downloads/'.
                             'index.html';
            my $PackManagers='https://en.wikipedia.org/wiki/'.
                             'List_of_software_package_management_systems';
            my $w='      ';
            my $die="\n$w ".
               "FATAL ERROR! : Cannot locate 'Berkeley DB'. This C Library".
               " \n$w                is required to install FullAuto".
               "\n$w                (Hint: goto\n".
               "\n$w $BerkDownload\n".
               "\n$w                 for Berkeley DB Source Code. Binary".
               " versions".
               "\n$w                 of the Library are widely available via".
               "\n$w                 package managers such as yum and apt-get".
               "\n$w                 See:\n".
               "\n$w $PackManagers).".
               "\n\n";
            fa_die($die);
         }
      }
   }
} elsif ($^O eq 'cygwin') {
   my $uname=`/bin/uname` || fa_die($!);
   my $uname_all=`/bin/uname -a` || fa_die($!);
   $uname_all.=$uname;
   $ENV{'BERKELEYDB_INCLUDE'}='/usr/include';
   $ENV{'BERKELEYDB_LIB'}='/usr/lib';
   if ($uname_all=~/WOW64|x86_64/) {
      $ENV{'BERKELEYDB_NAME'}='-ldb';
      $ENV{'DB_FILE_NAME'}='-ldb';
   } else {
      $ENV{'BERKELEYDB_NAME'}='-ldb-4.8';
      $ENV{'DB_FILE_NAME'}='-ldb-4.8';
   }
   $ENV{'DB_FILE_INCLUDE'}='/usr/include';
   $ENV{'DB_FILE_LIB'}='/usr/lib';
}

if (grep { /-*add[-_]?dependencies/i } @ARGV) {
   my @download=download_berkeleydb();
   `mkdir -p 'dependencies/BerkeleyDB'` unless
      -e 'dependencies/BerkeleyDB';
   `rm -rf dependencies/BerkeleyDB/*`;
   File::Copy::move($download[0],
      "dependencies/BerkeleyDB/$download[2].tar.gz");
   File::Copy::move($download[1],
      "dependencies/BerkeleyDB/$download[2].tar.gz.md5");
   require File::Copy;
   open(MO,"<MANIFEST");
   open(MN,">MANIFEST_NEW");
   while (my $file=<MO>) {
      next if $file=~/dependencies\/CPAN/s;
      next if $file=~/dependencies\/BerkeleyDB/s;
      next if $file=~/demo.*exe/s;
      print MN $file;
   }
   close MO;close MN;
   File::Copy::move('MANIFEST_NEW','MANIFEST');
   open(MF,">>MANIFEST") || fa_die("Cannot open MANIFEST: $!\n");
   my $found=`find dependencies/CPAN -type f`;
   $found.=`find dependencies/BerkeleyDB -type f`;
   my @found=split "\n",$found;
   open(MF,">>MANIFEST") || fa_die("Cannot open MANIFEST: $!\n");
   foreach my $fnd (@found) {
      print MF "$fnd\n";
   }
   print MF "demo/pscp.exe\n";
   print MF "demo/putty.exe\n";
   print MF "demo/puttygen.exe\n";
   print MF "demo/runputty.exe\n";
   print MF "demo/puttykey.exe\n";
   print MF "demo/engine.exe\n";
   print MF "demo/puttycfg.exe\n";
   print MF "demo/puttyyes.exe\n";
   close MF;
} else {
   require File::Copy;
   open(MO,"<MANIFEST");
   open(MN,">MANIFEST_NEW");
   while (my $file=<MO>) {
      next if $file=~/dependencies\/CPAN/s;
      next if $file=~/dependencies\/BerkeleyDB/s;
      print MN $file;
   }
   close MO;close MN;
   File::Copy::move('MANIFEST_NEW','MANIFEST');
}

chdir $cwd;

if ($get_BerkeleyDB) {

   do {
      local $SIG{__DIE__}; # No sigdie handler;
      my $p='BerkeleyDB';
      eval "use $p;1" or
      do {
         print"==> $p required."
         and print "*** Installing $p\n"
         and
         do {
            eval{
               local $SIG{__DIE__}; # No sigdie handler
               require CPAN;
               CPAN::Shell->force('install',$p);
            };
            #eval "use $p;1" ||
            #   fa_die("$@ *** Please manually install $p from cpan.org first...\n");
         }
      }
   }
}

chdir $cwd;

my $x=1;
if ($x==0) {
my $B_flag=1;
while (1) {
   eval {
      local $SIG{__DIE__}; # No sigdie handler
      my %hash=();
      require BerkeleyDB;
      my $db = tie %hash, "BerkeleyDB::Btree",
          -Filename => "fullauto_test_for_db_creation.db",
          -Flags =>  BerkeleyDB::DB_CREATE()
      or fa_die("Cannot tie fullauto_test_for_db_creation.db: $!");
      undef $db;
      untie %hash;
      unlink "fullauto_test_for_db_creation.db";
   };
   if ($@) {
      if (-1<index $@,'libgcc_s.so.1' && $B_flag) {
         if (-e '/usr/local/lib/libgcc_s.so.1') {
            `ln -s /usr/local/lib/libgcc_s.so.1 /usr/lib/libgcc_s.so.1`;
            # Flush inheritance caches
            @{BerkeleyDB::ISA} = ();
            my $symtab = 'BerkeleyDB::';
            # Delete all symbols except other namespaces
            for my $symbol (keys %$symtab) {
               next if $symbol =~ /\A[^:]+::\z/;
               delete $symtab->{$symbol};
            }
            delete $INC{'BerkeleyDB.pm'};
            $B_flag=0;
            next;
         }
      }
      my $die=<<END;
$@
   FATAL ERROR! : Cannot create 'fullauto_test_for_db_creation.db'
                  You may be missing the Berkeley DB 'c' library.
                  This 'c' library is required to install FullAuto.
END
      if ($^O eq 'cygwin') {
         my $uname=`/bin/uname`;
         my $stup='setup-x86.exe';
         $stup='setup-x86_64.exe' if $uname=~/i686/ || msw64bit();
         $die.="\n(Hint: Run Cygwin $stup and install Oracle Berkley ".
               "DB under the Category 'Database' ).";
      } else {
         $die.="\n(Hint: goto ->  https://www.oracle.com/technetwork/".
               "database/database-technologies/berkeleydb/downloads/".
               "index.html ).";
      }
      $die.="\n\n";
      fa_die($die);
   }
   last
}
}

sub download_berkeleydb {

   my $source=$last_known_good_location;
   FA::LWP::UserAgent->config;
   print "Fetching with LWP:\n  $source\n";
   my $Ua;
   eval {
      local $SIG{__DIE__}; # No sigdie handler;
      $Ua = FA::LWP::UserAgent->new(
            timeout=>300,show_progress=>1)
   };
   if ($@) {
      $CPAN::Frontend->mywarn(
         "ERROR: FA::LWP::UserAgent->new dies with $@\n");
   } else {
      my($var);
      $Ua->proxy('http', $var)
         if $var = $CPAN::Config->{http_proxy} ||
         $ENV{http_proxy};
      $Ua->no_proxy($var)
         if $var = $CPAN::Config->{no_proxy} || $ENV{no_proxy};
   }
   my %errors = ('500'=>'Bad hostname supplied',
                 '404'=>'URL not found',
                 '403'=>'URL forbidden',
                 '401'=>'Authorization failed',
                 '400'=>'Bad request found',
                 '302'=>'Redirected URL'
   );
   my $md5filename='';my $req='';my $res='';
   my $already_downloaded=0;
   my $site='download.oracle.com';
   $source=~
      s/^.*?(http:\/\/$site\/)(?:otn\/)*(b.*?\d.tar.gz).*$/$1$2/s;
   my $file=$2;
   my $file=substr($file,(index $file,'/')+1,-7);
   my $fh='';my $filename='';my $suffix='.tar.gz';
   if (grep  { /BDB/ } @ARGV) {
      $already_downloaded=1;
      $filename=$ARGV[$#ARGV];
   } else {
      $req = HTTP::Request->new(GET => $source);
      $req->header('Accept-Encoding' => 'gzip, compress');
      $res = $Ua->request($req);
      my $fh='';my $suffix='.tar.gz';
      ($fh,$filename)=get_temp_file($file,$suffix);
      if ($res->is_success) {
         print " + request successful.\n"
            if $CPAN::DEBUG;
         print $fh $res->content;
         close $fh;
      } else {
         my $status_line=$res->status_line;
         ($status_line) = ($status_line =~ /(\d+)/);
         if (defined($errors{$status_line})) {
            print(
               "LWP failed (1) with code $status_line, ",
               "message $errors{$status_line}\n".
               "Please check your connection to the Internet!\n",
               $status_line,
               $res->message,
            );
         } else {
            print(
               "LWP failed (2) with an Unknown Error\n".
               "Please check your connection to the Internet!\n",
            );
         }
         fa_die();
      }
      print(qq{ + saved content to $filename \n})
         if $CPAN::DEBUG;
      my $md5fh='';
      ($md5fh,$md5filename)=get_temp_file($file,$suffix.'.md5');
      $req = HTTP::Request->new(GET => $source.'.md5');
      $req->header('Accept-Encoding' => 'gzip, compress');
      $res = $Ua->request($req);
      if ($res->is_success) {
         print " + request successful.\n"
            if $CPAN::DEBUG;
         print $md5fh $res->content;
         close $md5fh;
      } else {
         my $status_line=$res->status_line;
         ($status_line) = ($status_line =~ /(\d+)/);
         if (defined($errors{$status_line})) {
            print(
               "LWP failed (3) with code $status_line, ",
               "message $errors{$status_line}\n".
               "Please check your connection to the Internet!\n",
               $status_line,
               $res->message,
            );
         } else {
            print(
               "LWP failed (4) with an Unknown Error\n".
               "Please check your connection to the Internet!\n",
            );
         }
         fa_die();
      }
      print(qq{ + saved md5 content to $md5filename \n})
         if $CPAN::DEBUG;
      open(MH,"<$md5filename") || fa_die($!);
      my $mhf=<MH>;
      close(MH);
      my $checksum=$mhf;
      $checksum=~s/^\s*(\S+)\s+.*$/$1/s;
      open(FILE, $filename) or fa_die("Can't open '$file': $!");
      binmode(FILE);
      require Digest::MD5;
      import Digest::MD5;
      my $digestmd5=Digest::MD5->new->addfile(*FILE)->hexdigest;
      if ($checksum eq $digestmd5) {
         print(qq{ + CHECKSUM Test for $filename *PASSED* \n})
            if $CPAN::DEBUG;
      } else {
         print "CHECKSUM test for $filename *FAILED*\n";
         print "CALCULATED=$digestmd5 and ",
               "DOWNLOADED=$checksum\n";
         print "\nPress ANY key to terminate FullAuto ",
               "installation ...\n";
         <STDIN>;
         fa_die("FATAL ERROR! : ".
             "CHECKSUM Test for $filename *FAILED*\n");
      }
      close(FILE);
      if (grep { /-*add[-_]?dependencies/i } @ARGV) {
         Term::ReadKey::ReadMode(0);
         return $filename,$md5filename,$file;
      } else {
         cpan_gunzip_and_untar();
         unless (keys %amazon) {
            my $so=fa_system($CPAN::Config->{gzip}." -d $filename");
            if ($so==-1) {
               fa_die("Cannot gunzip $filename: $!\n");
            }
            $filename=~s/\.gz$//;
         }
      }
   }
   if (keys %amazon) {
      unless (exists $amazon{'freebsd'}) {
         unless ($already_downloaded) {
            select STDOUT;
            $log->close() if $log && -1<index $log,'*';
            if (grep { /-*add[-_]?dependencies/i } @ARGV) {
               exec 'sudo',$^X,'Makefile.PL','add_dependencies',
                    'BDB',$filename;
            } else {
               exec 'sudo',$^X,'Makefile.PL','BDB',$filename;
            }
         }
         my $so=fa_system($CPAN::Config->{gzip}." -d $filename");
         if ($so==-1) {
            fa_die("Cannot gunzip $filename: $!\n");
         } else {
            $filename=~s/\.gz$//;
         }
         print "***** Untar1: sudo ",
            $CPAN::Config->{tar}," xvf $filename\n";
         fa_system("sudo ".$CPAN::Config->{tar}." xvf $filename");
      } else {
         unless ($already_downloaded) {
            select STDOUT;
            $log->close() if $log && -1<index $log,'*';
            if (grep { /-*add[-_]?dependencies/i } @ARGV) {
               exec 'sudo',$^X,'Makefile.PL','add_dependencies',
                    'BDB',$filename;
            } else {
               exec 'sudo',$^X,'Makefile.PL','BDB',
                    $filename;
            }
         }
         my $so=fa_system($CPAN::Config->{gzip}." -d $filename");
         if ($so==-1) {
            fa_die("Cannot gunzip $filename: $!\n");
         }  else {
            $filename=~s/\.gz$//;
         }
         print "***** Untar2: ",
            $CPAN::Config->{tar}," xvf $filename\n";
         fa_system($CPAN::Config->{tar}." xvf $filename");
      }
   } else {
      print "***** Untar3: ",
         $CPAN::Config->{tar}," xvf $filename\n";
      fa_system($CPAN::Config->{tar}." xvf $filename");
   }
   $filename=~/^.*\/(.*)_(.*).tar$/;
   $filename=$1;
   my $uniq=$2;
   #File::Copy::move("$filename","${filename}_$uniq");
   File::Copy::move("$filename","$filename.NC_$uniq");
   my $ver=$file;
   $ver=~s/_.*$//;
   $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
   my $pre="/usr/local/BerkeleyDB.$ver";
   $pre=$PREFIX."BerkeleyDB$ver" if $PREFIX;
   build_berkeleydb($filename,$uniq,$pre,$PREFIX,'');
   unless (exists $ENV{'BERKELEYDB_INCLUDE'} &&
         $ENV{'BERKELEYDB_INCLUDE'}) {
      my $BerkDownload='https://www.oracle.com/technetwork/database/'.
                       'database-technologies/berkeleydb/downloads/'.
                       'index.html';
      my $PackManagers='https://en.wikipedia.org/wiki/'.
                       'List_of_software_package_management_systems';
      my $w='      ';
      my $die="\n$w ".
         "FATAL ERROR! : Cannot locate 'Berkeley DB'. This C Library".
         " \n$w                is required to install FullAuto".
         "\n$w                (Hint: goto\n".
         "\n$w $BerkDownload\n".
         "\n$w                 for Berkeley DB Source Code. Binary".
         " versions".
         "\n$w                 of the Library are widely available via".
         "\n$w                 package managers such as yum and apt-get".
         "\n$w                 See:\n".
         "\n$w $PackManagers).".
         "\n\n";
      fa_die($die);
   }

}


sub download_berkeleydb_BAK {

   my $url=
      'https://www.oracle.com/technetwork/database/'.
      'database-technologies/berkeleydb/downloads/'.
      'index.html';
   if ($CPAN::META->has_usable('LWP')) {
      FA::LWP::UserAgent->config;
      print "Fetching with LWP:\n  $url\n";
      my $Ua;
      eval {
         local $SIG{__DIE__}; # No sigdie handler;
         $Ua = FA::LWP::UserAgent->new(
               timeout=>300,show_progress=>1)
      };
      if ($@) {
         $CPAN::Frontend->mywarn(
            "ERROR: FA::LWP::UserAgent->new dies with $@\n");
      } else {
         my($var);
         $Ua->proxy('http', $var)
            if $var = $CPAN::Config->{http_proxy} ||
            $ENV{http_proxy};
         $Ua->no_proxy($var)
            if $var = $CPAN::Config->{no_proxy} || $ENV{no_proxy};
      }
      my $req = HTTP::Request->new(GET => $url);
      $req->header('Accept' => 'text/html');
      my $res = $Ua->request($req);
      my $BDB_selection='NON-ENCRYPTED';
      if ($res->is_success) {
         print " + request successful.\n"
            if $CPAN::DEBUG;
         my $source=$res->content;
         my $site='download.oracle.com';
         $source=~
           s/^.*?(http:\/\/$site\/)(?:otn\/)*(b.*?\d.tar.gz).*$/$1$2/s;
         my $file=$2;
         my $file=substr($file,(index $file,'/')+1,-7);
         my $ver=$file;
         $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
         my $timeout=120;my $a='';my $w="      ";
         my $pre="/usr/local/BerkeleyDB.$ver";
         $pre=$PREFIX."BerkeleyDB$ver" if $PREFIX;
         my $berkeley_banner=<<END;

         *** THIS SCREEN WILL TIMEOUT AND PROCEED WITH Berkeley DB
                      INSTALLATION in 5 MINUTES ***

   Berkeley DB is a file-based (lightweight) database that FullAuto uses for
   storing and retrieving credentials and persistence data. Berkeley DB is
   maintained by Oracle Corporation and hosted at Oracle.com. It has the same
   open source license as FullAuto: GNU Affero General Public License V3.0.
   The default version of Berkeley DB that FullAuto will install and use is
   the latest **NON-ENCRYPTED** version. There is an option to choose
   Encrypted on the next screen.

         There is **NO WARRANTY** for Berkeley DB. USE AT YOUR RISK!

   FullAuto setup will download source code from Oracle.com and build it. It
   will be installed into:   $pre
END

               my $berkeleybanner=<<END;

         *** THIS SCREEN WILL TIMEOUT AND PROCEED WITH Berkeley DB
                      INSTALLATION in 5 MINUTES ***







END

               my $encrypted_banner=<<END;

   From http://http://docs.oracle.com/cd/E17076_03/html/index.html:

   "Berkeley DB releases optionally include strong cryptographic support;
   this release DOES contain cryptographic support. Export/import and/or
   use of cryptography software, or even communicating technical details
   about cryptography software, is illegal in some parts of the world. You
   are strongly advised to pay close attention to any export/import and/or
   use laws which apply to you when you import a release of Berkeley DB
   including cryptography to your country or re-distribute source code
   from it in any way."

   FullAuto does *NOT* utilize the encrypted features of Berkeley DB, and
   only offers to install the encrypted version as a courtesy. You are
   advised to install the NON-ENCRYPTED version unless you have specific
   reasons for needing the encrypted one.
END

         my %encryted_berkeley=(

            Name => 'encrypted_berkeley',
            Item_1 => {

               Text => "Install NON-ENCRYPTED Berkeley DB".
                       " ( Recommended! )",

            },

            Item_2 => {

               Text => "Install Encrypted Berkeley DB",

            },
            Banner => $encrypted_banner,

         );

         my %berkeleymenu=(

             Name => 'berkeleymenu',
             Item_1 => {

                Text => "Install NON-ENCRYPTED Berkeley DB",

             },
             Item_2 => {

                Text => "Install Encrypted Berkeley DB",
                Result => \%encryted_berkeley,

             },
             Item_3 => {

                Text => "Exit FullAuto Setup",

             },
             Scroll => 1,
             Banner => $berkeleybanner,

         );
         my %berkeley_menu=(

            Name   => 'berkeley_menu',
            Result => \%berkeleymenu,
            Banner => $berkeley_banner,

         );
         my $already_downloaded=0;
         my $filename='';
         unless (grep { /Encrypted/i } @ARGV) {
            unless (keys %amazon) {
               {
                  local $SIG{__DIE__}; # No sigdie handler
                  eval {
                     local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
                     alarm $timeout;
                     $BDB_selection=Menu(\%berkeley_menu);
                     alarm 0;
                  };
                  if ($@) {
                     # timed out
                     $BDB_selection='NON-ENCRYPTED';
                     $source=~s/tar.gz/NC.tar.gz/;
                  } elsif ($BDB_selection=~/\]quit\[|Exit/s) {
                     print "\n";
                     exit;
                  } elsif (-1<index $BDB_selection,'Encrypted') {
                     $BDB_selection='Encrypted';
                  } else {
                     $source=~s/tar.gz/NC.tar.gz/;
                  } alarm 0;
               };
            } else {
               $BDB_selection='NON-ENCRYPTED';
               $source=~s/tar.gz/NC.tar.gz/;
            }
         } elsif (grep  { /Encrypted/ } @ARGV) {
            $BDB_selection='Encrypted';
            $already_downloaded=1;
            $filename=$ARGV[$#ARGV];
         } else {
            $source=~s/tar.gz/NC.tar.gz/;
            $already_downloaded=1;
            $filename=$ARGV[$#ARGV];
         }
         my $fh='';
         my $suffix=($BDB_selection eq 'Encrypted')?
               '.tar.gz':'.NC.tar.gz';
         unless ($already_downloaded) {
            ($fh,$filename)=get_temp_file($file,$suffix);
            my $end_flag=0;my $md5filename='';
            my %errors = ('500'=>'Bad hostname supplied',
                          '404'=>'URL not found',
                          '403'=>'URL forbidden',
                          '401'=>'Authorization failed',
                          '400'=>'Bad request found',
                          '302'=>'Redirected URL'
            );
            while (1) {
               $req = HTTP::Request->new(GET => $source);
               $req->header('Accept-Encoding' => 'gzip, compress');
               $res = $Ua->request($req);
               my $success=1;
               if ($res->is_success) {
                  print " + request successful.\n"
                     if $CPAN::DEBUG;
                  print $fh $res->content;
                  close $fh;
               } else {
                  my $status_line=$res->status_line;
                  ($status_line) = ($status_line =~ /(\d+)/);
                  if (defined($errors{$status_line})) {
                     print(
                        "LWP failed with code $status_line, ",
                        "message $errors{$status_line}\n".
                        "Please check your connection to the Internet!\n",
                        $status_line,
                        $res->message,
                     );
                     if (!$end_flag && ($status_line eq '404')) {
                        unlink $filename;
                        $source=$last_known_good_location;
                        $end_flag=1;my $rt=qr/b.*?\d.tar.gz/;
                        my $h=qr/http:\/\/$site\//;
                        $source=~s/^.*?($h)(?:otn\/)*($rt).*$/$1$2/s;
                        $file=$2;
                        ($suffix=$file)=~s/^.*(([.]NC)*.tar.gz)$/$1/;
                        $BDB_selection='Encrypted' if $1;
                        $file=substr($file,(index $file,'/')+1,-7);
                        ($fh,$filename)=get_temp_file($file,$suffix);
                        $ver=$file;
                        $ver=~s/_.*$//;
                        $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
                        $pre="/usr/local/BerkeleyDB.$ver";
                        $pre=$PREFIX."BerkeleyDB$ver" if $PREFIX;
                        next;
                     }
                  } else {
                     print(
                        "LWP failed with an Unknown Error\n".
                        "Please check your connection to the Internet!\n",
                     );
                  }
                  $success = 0;
                  close $fh;
                  last;
               }
               print(qq{ + saved content to $filename \n})
                  if $CPAN::DEBUG;
               my $md5fh='';
               ($md5fh,$md5filename)=get_temp_file($file,$suffix.'.md5');
               $req = HTTP::Request->new(GET => $source.'.md5');
               $req->header('Accept-Encoding' => 'gzip, compress');
               $res = $Ua->request($req);
               if ($res->is_success) {
                  print " + request successful.\n"
                     if $CPAN::DEBUG;
                  print $md5fh $res->content;
                  close $md5fh;
               } else {
                  my $status_line=$res->status_line;
                  ($status_line) = ($status_line =~ /(\d+)/);
                  if (defined($errors{$status_line})) {
                     print(
                        "LWP failed with code $status_line, ",
                        "message $errors{$status_line}\n".
                        "Please check your connection to the Internet!\n",
                        $status_line,
                        $res->message,
                     );
                     if (!$end_flag && ($status_line eq '404')) {
                        unlink $filename;
                        $source=$last_known_good_location;
                        $end_flag=1;my $rt=qr/b.*?\d.tar.gz/;
                        my $h=qr/http:\/\/$site\//;
                        $source=~s/^.*?($h)(?:otn\/)*($rt).*$/$1$2/s;
                        $file=$2;
                        ($suffix=$file)=~s/^.*(([.]NC)*.tar.gz)$/$1/;
                        $BDB_selection='Encrypted' if $1;
                        $file=substr($file,(index $file,'/')+1,-7);
                        ($fh,$filename)=get_temp_file($file,$suffix);
                        $ver=$file;
                        $ver=~s/_.*$//;
                        $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
                        $pre="/usr/local/BerkeleyDB.$ver";
                        $pre=$PREFIX."BerkeleyDB$ver" if $PREFIX;
                        next;
                     }
                  } else {
                     print(
                        "LWP failed with an Unknown Error\n".
                        "Please check your connection to the Internet!\n",
                     );
                  }
                  $success = 0;
                  close $fh;
                  last;
               }
               print(qq{ + saved md5 content to $md5filename \n})
                  if $CPAN::DEBUG;
               open(MH,"<$md5filename") || fa_die($!);
               my $mhf=<MH>;
               close(MH);
               my $checksum=$mhf;
               $checksum=~s/^\s*(\S+)\s+.*$/$1/s;
               open(FILE, $filename) or fa_die("Can't open '$file': $!");
               binmode(FILE);
               require Digest::MD5;
               import Digest::MD5;
               my $digestmd5=Digest::MD5->new->addfile(*FILE)->hexdigest;
               if ($checksum eq $digestmd5) {
                  print(qq{ + CHECKSUM Test for $filename *PASSED* \n})
                     if $CPAN::DEBUG;
               } else {
                  print "CHECKSUM test for $filename *FAILED*\n";
                  print "CALCULATED=$digestmd5 and ",
                        "DOWNLOADED=$checksum\n";
                  print "\nPress ANY key to terminate FullAuto ",
                        "installation ...\n";
                  <STDIN>;
                  fa_die("FATAL ERROR! : ".
                      "CHECKSUM Test for $filename *FAILED*\n");
               }
               close(FILE);
               last;
            }
            if (grep { /-*add[-_]?dependencies/i } @ARGV) {
               Term::ReadKey::ReadMode(0);
               return $filename,$md5filename,$file;
            } else {
               cpan_gunzip_and_untar();
               unless (keys %amazon) {
                  my $so=fa_system($CPAN::Config->{gzip}." -d $filename");
                  if ($so==-1) {
                     fa_die("Cannot gunzip $filename: $!\n");
                  }
               }
               $filename=~s/\.gz$//;
            }
         }
         if (keys %amazon) {
            unless (exists $amazon{'freebsd'}) {
               unless ($already_downloaded) {
                  select STDOUT;
                  $log->close() if $log && -1<index $log,'*';
                  if (grep { /-*add[-_]?dependencies/i } @ARGV) {
                     exec 'sudo',$^X,'Makefile.PL','add_dependencies',
                          $BDB_selection,$filename;
                  } else {
                     exec 'sudo',$^X,'Makefile.PL',$BDB_selection,
                          $filename;
                  }
               }
               my $so=fa_system($CPAN::Config->{gzip}." -d $filename");
               if ($so==-1) {
                  fa_die("Cannot gunzip $filename: $!\n");
               }
               print "***** Untar1: sudo ",
                  $CPAN::Config->{tar}," xvf $filename\n";
               fa_system("sudo ".$CPAN::Config->{tar}." xvf $filename");
            } else {
               unless ($already_downloaded) {
                  select STDOUT;  
                  $log->close() if $log && -1<index $log,'*';
                  if (grep { /-*add[-_]?dependencies/i } @ARGV) {
                     exec 'sudo',$^X,'Makefile.PL','add_dependencies',
                          $BDB_selection,$filename;
                  } else {
                     exec 'sudo',$^X,'Makefile.PL',$BDB_selection,
                          $filename;
                  }
               }
               my $so=fa_system($CPAN::Config->{gzip}." -d $filename");
               if ($so==-1) {
                  fa_die("Cannot gunzip $filename: $!\n");
               }
               print "***** Untar2: ",
                  $CPAN::Config->{tar}," xvf $filename\n";
               fa_system($CPAN::Config->{tar}." xvf $filename");
            }
         } else {
            print "***** Untar3: ",
               $CPAN::Config->{tar}," xvf $filename\n";
            fa_system($CPAN::Config->{tar}." xvf $filename");
         }
         my $uniq='';
         if ($BDB_selection eq 'Encrypted' || -1==index $filename,'.NC.') {
            $filename=~/^.*(......).tar$/;
            $uniq=$1;
            $filename=~s/........tar$//;
            `mv -f $filename ${filename}_$uniq`;
         } else {
            $filename=~/^.*(......).NC.tar$/;
            $uniq=$1;
            $filename=~s/........NC.tar$//;
            `mv -f $filename.NC $filename.NC_$uniq`;
         }
         my $ver=$filename;
         $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
         my $timeout=120;my $a='';my $w="      ";
         my $pre="/usr/local/BerkeleyDB.$ver";
         $pre=$PREFIX."BerkeleyDB$ver" if $PREFIX;
         build_berkeleydb($filename,$uniq,$pre,$PREFIX,$BDB_selection);
      } else {
         if ($res->is_error(500)) {
            print(sprintf(
               "LWP failed with code[%s], message[%s]\n".
               "Please check your connection to the Internet!\n",
               $res->code,
               $res->message,
            ));
         } else {
            print(sprintf(
               "LWP failed with code[%s], message[%s]\n",
               $res->code,
               $res->message,
            ));
         }
      }
   } else {
      $CPAN::Frontend->mywarn("  LWP not available\n");
   }

}

sub build_berkeleydb {

   my $filename=$_[0];
   my $uniq=$_[1];
   my $pre=$_[2]||'';
   my $PREFIX=$_[3]||'';
   my $BDB_selection=$_[4]||'';
   #my $args=' --enable-sql --enable-sql_compat';
   my $args='';
   if ($PREFIX) {
      $args.=' --prefix="'.$PREFIX.'"';
   }
   my $one=1;
   WH: while ($one) {
      if ($BDB_selection eq 'Encrypted') {
         open(FH,
            "cd ${filename}_$uniq/build_unix;".
            "../dist/configure$args 2>&1|")
         || warn $!;
      } else {
         open(FH,
            "cd ${filename}.NC_$uniq/build_unix;".
            "../dist/configure$args 2>&1|")
         || warn $!;
      }
      while (my $line=<FH>) {
         if (-1<index $line,'C compiler cannot create executables') {
            $ENV{'CC'}='gcc';
            next WH;
         }
      }
      last;
   }
   close FH;
   unless ($CPAN::Config->{make}) {
      if (-e '/usr/bin/make') {
         $CPAN::Config->{make}='/usr/bin/make';
      } elsif (-e '/usr/local/bin/make') {
         $CPAN::Config->{make}='/usr/local/bin/make';
      }
   }
   if ($BDB_selection eq 'Encrypted') {
      print "*** Starting Encrypted BerkeleyDB build\n";
      fa_system("(cd ${filename}_$uniq/build_unix;".
            $CPAN::Config->{make}." install) 2>&1")
         || warn $!;
      print "*** Completed Encrypted BerkeleyDB build\n";
   } else {
      print "*** Starting Non-Encrypted BerkeleyDB build\n";
      fa_system("(cd ${filename}.NC_$uniq/build_unix;".
         $CPAN::Config->{make}." install) 2>&1")
         || warn $!;
      print "*** Completed Non-Encrypted BerkeleyDB build\n";
   }
   my $ver=$filename;
   $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
   $berkeleydb=$pre.'/lib';
   my $header_to_use=$pre.'/include';
   $ENV{'BERKELEYDB_INCLUDE'}=$header_to_use;
   $ENV{'BERKELEYDB_LIB'}=$berkeleydb;
   $ENV{'BERKELEYDB_NAME'}="-ldb-$ver";
   $ENV{'DB_FILE_INCLUDE'}=$header_to_use;
   $ENV{'DB_FILE_LIB'}=$berkeleydb;
   $ENV{'DB_FILE_NAME'}="-ldb-$ver";
   $ENV{'LD_LIBRARY_PATH'}=$berkeleydb;
   $ENV{'LD_RUN_PATH'}=$ENV{'LD_LIBRARY_PATH'};

}

sub get_temp_file {

   my $file=$_[0];
   my $suffix=$_[1];
   my $fh='';my $filename='';
   if ($CPAN::META->has_usable("File::Temp")) {
      $fh = File::Temp->new(
            dir      => cwd(),
            template => "${file}_XXXXXX",
            suffix => $suffix,
            unlink => 0,
           );
      $filename = $fh->filename;
   } else {
      $fh = FileHandle->new;
      $filename = "${file}_${$}$suffix";
   }
   chomp($filename);
   return $fh,$filename;

}

sub cpan_gunzip_and_untar {

   unless ($CPAN::Config->{gzip}) {
      if (-e '/usr/bin/gzip') {
         $CPAN::Config->{gzip}='/usr/bin/gzip';
      } elsif (-e '/usr/local/bin/gzip') {
         $CPAN::Config->{gzip}='/usr/local/bin/gzip';
      } else {
         print "\n\n   FATAL ERROR!: The 'gzip' utility is".
            " missing.\n".
            "\n\n   Please report any bugs and send any",
            "\n   questions, thoughts or feedback to:",
            "\n\n      Brian.Kelly\@FullAuto.com.",
            "\n\n   Press ANY key to exit.\n\n";<STDIN>;
            exit 1;
      }
   }
   unless ($CPAN::Config->{tar}) {
      if (-e '/usr/sfw/bin/gtar') {
         $CPAN::Config->{tar}='/usr/sfw/bin/gtar';
      } elsif (-e '/usr/bin/tar') {
         $CPAN::Config->{tar}='/usr/bin/tar';
      } elsif (-e '/usr/local/bin/tar') {
         $CPAN::Config->{tar}='/usr/local/bin/tar';
      } else {
         print "\n\n   FATAL ERROR!: The 'tar' utility is".
            " missing.\n".
            "\n\n   Please report any bugs and send any",
            "\n   questions, thoughts or feedback to:",
            "\n\n      Brian.Kelly\@FullAuto.com.",
            "\n\n   Press ANY key to exit.\n\n";<STDIN>;
            exit 1;
      }
   }

}

sub find_windows_firefox {

   # Let's look for Firefox
   my $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
               'Mozilla\\Mozilla Firefox" 2>&1';
   $firefox=`$firefox`;
   $firefox=~tr/\0-\11\13-\37\177-\377//d;
   chomp($firefox);
   $firefox=~s/^.*CurrentVersion\s*REG_SZ\s*(.*?)\n.*$/$1/s;
   $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
            "Mozilla\\Mozilla Firefox\\$firefox\\Main\" 2>&1";
   fa_system($firefox);
   $firefox=~tr/\0-\11\13-\37\177-\377//d;
   chomp($firefox);
   $firefox=~s/^.*Path(?:To)*Exe\s*REG_SZ\s*(.*\.exe).*$/$1/s;
   $firefox=~s/\s*$//s;
   my $fftest=substr($firefox,0,2) if 1<length $firefox;
   $fftest||='';
   my $selection='';
   if ($fftest=~/\w:|\/\w/) {
      $fftest=substr($firefox,0,(rindex $firefox,'\\'));
   } else {
      $fftest='';
   }
   if (-1<index $firefox,'unable to find') {
      unless ($install_firefox_without_asking) {
         # Ask if we should install
         my $one="YES - Install Mozilla Firefox & MozRepl\n\n";
         my %_askfirefox=(

            Label => '_askfirefox',
            Item_1 =>  {
                           Text   => "]C[",
                           Convey => [ $one,
                                       'NO  - DO *NOT* INSTALL Firefox' ],
                       },
            Scroll => 2,
            Banner=> "   *** THIS SCREEN WILL TIMEOUT IN 2 MINUTES ***\n\n".
                     "   Mozilla Firefox has an available add-on called ".
                     "MozRepl.\n\n   With Firefox equipped with MozRepl, ".
                     "FullAuto can do\n   extremely powerful WEB ".
                     "Automation!\n\n   Would you like the FullAuto ".
                     "installer to install Firefox\n   and MozRepl?\n\n",
         );
         {
            local $SIG{__DIE__}; # No sigdie handler
            eval {
               local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
               alarm 120;
               $selection=Term::Menus::Menu(\%_askfirefox);
               alarm 0;
            };
            if ($@) {
               $selection='DO_NOT_INSTALL';
            } else {
               chomp($selection);
               $selection='Install_Mozilla_Firefox'
                  if -1<index $selection,'Install Mozilla Firefox';
               $selection='DO_NOT_INSTALL'
                  if -1<index $selection,'*NOT* INSTALL';
               exit if $selection eq ']quit[';
            }
         };
      } else { $selection='Install_Mozilla_Firefox' }
      $install_firefox=$selection;
   } else { # Look for MozRepl
      my $up=$ENV{'USERPROFILE'};
      if (-1<index $up,'Documents') {
         $up.="\\Application Data\\Mozilla\\Firefox\\Profiles\\";
      } else {
         $up.="\\AppData\\Roaming\\Mozilla\\Firefox\\Profiles\\";
      }
      my @dirs=();
      if (-e $up) {
         opendir(DIR,$up);
         @dirs = readdir(DIR);
         closedir(DIR);
      }
      if (-1<$#dirs) {
         foreach my $profile (@dirs) {
            opendir(DIR,$up."\\$profile\\extensions");
            my @files = readdir(DIR);
            closedir(DIR);
            foreach my $file (@files) {
               if (-1<index $file,'mozrepl') {
                  return 0;
               }
            }
         }
      }
      unless ($install_firefox_without_asking) {
         # Ask if we should install
         my $one="YES - Install MozRepl Plugin for Firefox\n\n";
         my %_askfirefox=(

            Label => '_askfirefox',
            Item_1 =>  {
                           Text   => "]C[",
                           Convey => [ $one,'NO  - DO *NOT* INSTALL MozRepl' ],
                        },
            Scroll => 2,
            Banner=> "   Mozilla Firefox has an available add-on ".
                     "called MozRepl.\n\n   With Firefox equipped ".
                     "with MozRepl, FullAuto can do\n   extremely ".
                     "powerful WEB Automation!\n\n   Would you ".
                     "like the FullAuto installer to install ".
                     "the\n   MozRepl plugin?\n\n",
         );
         $selection=Term::Menus::Menu(\%_askfirefox);
         chomp($selection);
         $selection='Install_MozRepl'
            if -1<index $selection,'Install MozRepl Plugin';
         $selection='DO_NOT_INSTALL'
            if -1<index $selection,'*NOT* INSTALL';
         exit if $selection eq ']quit[';
      } else { $selection='Install_MozRepl' }
      $install_firefox=$selection;
   }
}

sub install_firefox {

   my $Ua;
   $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;
   if ($CPAN::META->has_usable('LWP')) {
      FA::LWP::UserAgent->config;
      eval {
         local $SIG{__DIE__}; # No sigdie handler;
         $Ua = FA::LWP::UserAgent->new(
               timeout=>300,show_progress=>1)
      };
      if ($@) {
         $CPAN::Frontend->mywarn(
         "ERROR: FA::LWP::UserAgent->new dies with $@\n");
      } else {
         my($var);
         $Ua->proxy('http', $var)
            if $var = $CPAN::Config->{http_proxy} ||
            $ENV{http_proxy};
         $Ua->no_proxy($var)
            if $var = $CPAN::Config->{no_proxy} || $ENV{no_proxy};
      }
      $Ua->ssl_opts( SSL_verify_mode => 'SSL_VERIFY_NONE' );
   } else {
      fa_die("Unable to install Firefox due to no LWP availability");
   }
   my $fftest='';
   unless ($install_firefox eq 'Install_MozRepl') {
      my $url='http://www.mozilla.org/en-US/firefox/all/';
      print "Fetching with LWP:\n  $url\n";
      my $req = HTTP::Request->new(GET => $url);
      $req->header('Accept' => 'text/html');
      my $res = $Ua->request($req);
      my $href='';
      if ($res->is_success) {
         print " + request successful.\n"
            if $CPAN::DEBUG;
         my $count=0;
         my $content = $res->decoded_content();
         if (utf8::is_utf8($content)) {
            binmode STDOUT,':utf8';
         } else {
            binmode STDOUT,':raw';
         }
         foreach my $line (split "\n", $content) {
            if ((-1<index $line, 'english (us) english (us)') ||
                  ((0<$count) && ($count<5))) {
               if ($count==3) {
                  $href=$line;
                  last;
               }
               $count++;
            }
         }
      }
      $href=~s/^.*href=["](.*?)["].*$/$1/;
      $href=~s/https/http/;
      $href=~s/&amp;/&/g;
      my $exe_name=substr($href,(rindex $href,'/'));
      $exe_name=~s/^.*?product=(.*?)[&].*$/$1/;
      $exe_name=~s/firefox-/Firefox Setup /;
      $req = HTTP::Request->new(GET => $href);
      $req->header('Accept' => 'text/html');
      $res = $Ua->request($req);
      if ($res->is_success) {
         print " + request successful.\n"
         if $CPAN::DEBUG;
         mkpath($cygwin_root_dir,1) unless -d $cygwin_root_dir;
         unless (-w $cygwin_root_dir) {
            print "\n\n   FATAL ERROR! - The current Cygwin directory: ".
                  "\n\n      ".$cygwin_root_dir."\n\n".
                  "   is not writable. Please change the permissions\n".
                  "   to writable before installing FullAuto.\n";
            print "\n   PRESS ANY KEY TO EXIT SETUP\n\n";
            <STDIN>;
            exit 1;
         }
         open(CP,">$cygwin_root_dir/${exe_name}.exe") || fa_die($!);
         binmode(CP);
         print CP $res->content;
         close CP;
         if ($^O eq 'cygwin') {
            `/usr/bin/chmod 777 \"$cygwin_root_dir/${exe_name}.exe\"`;
         } else {
            my $cygwin_loc=get_cygwin_location();
            fa_system('SET CYGWIN=nodosfilewarning & '.
                "cmd /c $cygwin_loc\\bin\\bash -lc ".
                "/usr/bin/chmod 777 \"$cygwin_root_dir/${exe_name}.exe\"");
         }
         `"$cygwin_root_dir/${exe_name}.exe" -ms`;
         # Let's look for Firefox
         my $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
                     'Mozilla\\Mozilla Firefox" 2>&1';
         $firefox=`$firefox`;
         $firefox=~tr/\0-\11\13-\37\177-\377//d;
         chomp($firefox);
         $firefox=~s/^.*CurrentVersion\s*REG_SZ\s*(.*?)\n.*$/$1/s;
         $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
                  "Mozilla\\Mozilla Firefox\\$firefox\\Main\" 2>&1";
         fa_system($firefox);
         $firefox=~tr/\0-\11\13-\37\177-\377//d;
         chomp($firefox);
         $firefox=~s/^.*Path(?:To)*Exe\s*REG_SZ\s*(.*\.exe).*$/$1/s;
         $firefox=~s/\s*$//s;
         $fftest=substr($firefox,0,2) if 1<length $firefox;
         $fftest||='';
         my $selection='';
         if ($fftest=~/\w:|\/\w/) {
            $fftest=substr($firefox,0,(rindex $firefox,'\\'));
         } else {
            $fftest='';
         }
      }
   } else {
      # Let's look for Firefox
      my $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
                  'Mozilla\\Mozilla Firefox" 2>&1';
      $firefox=`$firefox`;
      $firefox=~tr/\0-\11\13-\37\177-\377//d;
      chomp($firefox);
      $firefox=~s/^.*CurrentVersion\s*REG_SZ\s*(.*?)\n.*$/$1/s;
      $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
               "Mozilla\\Mozilla Firefox\\$firefox\\Main\" 2>&1";
      fa_system($firefox);
      $firefox=~tr/\0-\11\13-\37\177-\377//d; 
      chomp($firefox);
      $firefox=~s/^.*Path(?:To)*Exe\s*REG_SZ\s*(.*\.exe).*$/$1/s;
      $firefox=~s/\s*$//s;
      $fftest=substr($firefox,0,2) if 1<length $firefox;
      $fftest||='';
      my $selection='';
      if ($fftest=~/\w:|\/\w/) {
         $fftest=substr($firefox,0,(rindex $firefox,'\\'));
      } else {
         $fftest='';
      }
   }
   my $url='https://addons.mozilla.org/firefox/downloads/file/'.
        "138898/$mozrepl_file?src=dp-btn-primary";
   my $req = HTTP::Request->new(GET => $url);
   $req->header('Accept' => 'text/html');
   my $res = $Ua->request($req);
   my $href='';
   my $cygwin_loc=get_cygwin_location();
   my $clo=$cygwin_loc;
   my $mz="$clo\\$mozrepl_file";
   if ($res->is_success) {
      print " + request successful.\n"
         if $CPAN::DEBUG;
      open(CP,">$mz") || fa_die($!);
      binmode(CP);
      print CP $res->content;
      close CP;
      my $ff=$fftest.'\\firefox';
      my $mP=$PARdir;
      if ($^O eq 'cygwin') {
         $mz=~s/\\/\\\\/g;
         my $chmod_out=
               `chmod -v 777 \"$mP/bin/install_mozrepl_plugin\" 2>&1`;
         print "CYGCHMOD=$chmod_out\n" if $chmod_out;
         print "MOZREPL COMMAND=\"$mP/bin/install_mozrepl_plugin\" ".
               "\"$ff\" \"$mz\" 2>&1\n";
         my $output=
               `\"$mP/bin/install_mozrepl_plugin\" \"$ff\" \"$mz\" 2>&1`;
         print "CYGOUTPUT=$output\n" if $output;
      } else {
         my $output=
               `\"$mP\\bin\\install_mozrepl_plugin\" \"$ff\" \"$mz\" 2>&1`;
         print "WINOUTPUT=$output\n" if $output;
      }
   }
}

sub remove_sshd {
   my $sshd_account=$_[0];
   my $cygwin_loc=get_cygwin_location();
   my $clo=$cygwin_loc;
   $clo=~s/\\/\\\\/g;
   if (-e $cygwin_loc) {
      if ($^O eq 'cygwin') {
         my $srvcmd='export CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"/usr/bin/cygrunsrv --verbose --query sshd"';
         my $cygout=`$srvcmd 2>&1`;
         if ($cygout=~/^Account\s+: .\\$sshd_account$/m) {
            my $srvcmd='export CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\\\bin\\\\bash -lc ".
                       '"/usr/bin/cygrunsrv --remove sshd"';
            my $cygout=`$srvcmd 2>&1`;
         } elsif (-1==index $cygout,'service does not exist') {
            return 0;
         }
      } else {
         my $srvcmd='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"/usr/bin/cygrunsrv --verbose --query sshd"';
         my $cygout=`$srvcmd 2>&1`;
         if ($cygout=~/^Account\s+: .\\$sshd_account$/m) {
            my $srvcmd='SET CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\\\bin\\\\bash -lc ".
                       '"/usr/bin/cygrunsrv --remove sshd"';
            my $cygout=`$srvcmd 2>&1`;
         } elsif (-1==index $cygout,'service does not exist') {
            return 0;
         }
      }
      my $remove_out=`net user /delete sshd 2>&1`;
      if (-e "$cygwin_loc\\etc\\passwd") {
         do {
            local $^I='.bak'; # see perlvar(1)
            local @ARGV=("$cygwin_loc\\etc\\passwd");
            while(<>){
               s/^$sshd_account:.*\s*$//;
               s/^sshd:.*\s*$//;
               print;
            }
         };
      }
   }
   return 1;
}

sub test_windows_user_rights {

   my $user=$_[0];

   # Is Cygwin installed?
   my $cygwin_location=get_cygwin_location();

   # Adjust memory quotas for a process             (SeIncreaseQuotaPrivilege)
   # Create a token object                          (SeCreateTokenPrivilege)
   # Log on as a service                            (SeServiceLogonRight)
   # Replace a process level token
   #                                           (SeAssignPrimaryTokenPrivilege)

   # Act as part of the operating system            (SeTcbPrivilege)

   # >  And for security.....

   # Deny log on locally                         (SeDenyInteractiveLogonRight)
   # Deny access to this computer from the network   (SeDenyNetworkLogonRight)
   # Deny log on through Terminal Services
   #                                       (SeDenyRemoteInteractiveLogonRight)

   my $rights=`$cygwin_location\\bin\\editrights -u $user -l`;
   my $output='';
   if ((-1==index $rights,'SeServiceLogonRight') ||
         (-1==index $rights,'SeTcbPrivilege') ||
         (-1==index $rights,'SeCreateTokenPrivilege') ||
         (-1==index $rights,'SeAssignPrimaryTokenPrivilege') || 1) {
      my $die='DYING';
      my @missing_rights=();
      if (-1==index $rights,'SeTcbPrivilege') {
         unless ($output=
               `/bin/editrights -a SeTcbPrivilege -u $user`) {
            push @missing_rights, 'SeTcbPrivilege';
         }
      }
      if (-1==index $rights,'SeCreateTokenPrivilege') {
         my $prv='SeCreateTokenPrivilege';
         unless (`/bin/editrights -a $prv -u $user`) {
            push @missing_rights, 'SeCreateTokenPrivilege';
         }
      }
      if (-1==index $rights,'SeAssignPrimaryTokenPrivilege') {
         my $prv='SeAssignPrimaryTokenPrivilege';
         unless (`/bin/editrights -a $prv -u $user`) {
            push @missing_rights, 'SeAssignPrimaryTokenPrivilege';
         }
      }
      if (-1==index $rights,'SeServiceLogonRight') {
         my $prv='SeServiceLogonRight';
         unless (`/bin/editrights -a $prv -u $user`) {
            push @missing_rights, 'SeServiceLogonRight';
         }
      }
      if (-1<$#missing_rights) {
         my $mis=join "\n",map { "               $_" } @missing_rights;
         my $die="   FATAL ERROR! - The following priviliges are\n   ".
                 "               missing from the ID '".$user."':\n\n".
                 $mis."\n\n   An attempt was made to add these rights,\n".
                 "   but was not successul. Please contact your\n".
                 "   your Domain and Server Administrators for\n".
                 "   assistance.\n\n";
         fa_die($die);
      }
      my $gpout=`gpupdate 2>&1`;
      if (-1<index $gpout,'completed successfully') {
         @missing_rights=();
         if (-1==index $rights,'SeTcbPrivilege') {
            push @missing_rights, 'SeTcbPrivilege';
         }
         if (-1==index $rights,'SeCreateTokenPrivilege') {
            push @missing_rights, 'SeCreateTokenPrivilege';
         }
         if (-1==index $rights,'SeAssignPrimaryTokenPrivilege') {
            push @missing_rights, 'SeAssignPrimaryTokenPrivilege';
         }
         if (-1==index $rights,'SeServiceLogonRight') {
            push @missing_rights, 'SeServiceLogonRight';
         }
         if (-1<$#missing_rights) {
            my $mis=join "\n",map { "               $_" } @missing_rights;
            my $die="   FATAL ERROR! - The following priviliges were\n".
                    "                  added to the ID '".$user."':\n\n".
                    $mis."\n\n   However, these priviliges were\n".
                    "   subsequently removed by a Domain Global\n".
                    "   Policy Update. Please contact your Windows\n".
                    "   Domain and Server Administrators to have the\n".
                    "   Global Domain Policy changed for this ID.\n\n";
            fa_die($die);
         }
      }
   }
}

sub test_windows_user {

   my $sshd_account=$_[0];
   my $test_user=`net user $sshd_account 2>&1`;
   if (-1<index $test_user,'not be found') {
      my $return=&remove_sshd($sshd_account); 
      return 1;
   }
   # Is Cygwin installed?
   my $cygwin_location=get_cygwin_location();

   # Adjust memory quotas for a process             (SeIncreaseQuotaPrivilege)
   # Create a token object                          (SeCreateTokenPrivilege)
   # Log on as a service                            (SeServiceLogonRight)
   # Replace a process level token
   #                                           (SeAssignPrimaryTokenPrivilege)

   # Act as part of the operating system            (SeTcbPrivilege)

   # > 	And for security.....

   # Deny log on locally                         (SeDenyInteractiveLogonRight)
   # Deny access to this computer from the network   (SeDenyNetworkLogonRight)
   # Deny log on through Terminal Services 
   #                                       (SeDenyRemoteInteractiveLogonRight)

   if ($cygwin_location) {
      my $rights=`$cygwin_location\\bin\\editrights -u $sshd_account -l`;
      print "RIGHTS for $sshd_account ======>\n$rights\n<=======\n";
      if ((-1==index $rights,'SeServiceLogonRight') || 
            ((-1==index $rights,'SeDenyRemoteInteractiveLogonRight') &&
            (-1==index $rights,'SeDenyInteractiveLogonRight'))) {
         my $message=<<END;

   FullAuto Install has determined that the current
  \"$sshd_account\" user ID, lacks sufficient privileges
   to act as the sshd service ID;

      The needed privileges are:

         SeServiceLogonRight  SeCreateTokenPrivilege
         SeDenyInteractiveLogonRight  SeTcbPrivilege
         SeAssignPrimaryTokenPrivilege

   Use:  /bin/editrights -u $sshd_account -l
   to manually inspect these privileges.
   Some corporate environments enforce strict group
   rights from the Domain Controller, and these
   privileges may be surreptiously removed from the
   $sshd_account account without notice. Check with your
   Microsoft Infrastructure Admins if you suspect this
   may be a possibility with your setup. You will need
   to get an exception added to their configuration.
   Press ANY key to continue . . .

END
         print $message;
         <STDIN>;
         my $remove_out=`net user /delete $sshd_account 2>&1`;
         if (-1<index $remove_out,"command completed successfully") {
            my $return=&remove_sshd($sshd_account);
            return $return;
         } else {
            my $message=<<END;

   FullAuto Install attempted to remove the ID $sshd_account
   *before* trying a re-install but was unsuccessful:

   $remove_out

   Please remedy the situtation before
   trying FullAuto Install again.

   Please report any bugs and send any
   questions, thoughts or feedback to:

      Brian.Kelly\@FullAuto.com

   Press ANY key to exit.

END
            print $message;
            <STDIN>;
            exit 1;
         }
      }
      unless (-e "$cygwin_location\\var\\empty") {
         my $remove_out=`net user /delete $sshd_account 2>&1`;
         if (-1<index $remove_out,"command completed successfully") {
            my $return=&remove_sshd($sshd_account);
            return $return;
         } else {
            print "\n\n   FullAuto Install has determined that the.",
                  "\n   current sshd service setup was not completed",
                  "\n   correctly with the user ID \"$sshd_account\":",
                  "\n\n      The directory: $cygwin_location\\var\\empty",
                  "\n\n      does NOT exist.", 
                  "\n\n      FullAuto Install attempted to remove",
                  "\n   the ID before trying a re-install but",
                  "\n   was unsuccessful:\n\n   $remove_out.\n\n",
                  "\n\n   Please remedy the situtation before trying.",
                  "\n   FullAuto Install again.",
                  "\n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@FullAuto.com.",
                  "\n\n   Press ANY key to exit.\n\n";<STDIN>;
            exit 1;
         }
      }
      return 0;
   } else {
      return 0;
   }
}

sub windows_ver {
   # Thanks - http://ss64.org/viewtopic.php?id=879
   # and    - http://en.wikipedia.org/wiki/Ver_(command)
   my $output=`cmd /c ver`;
   if (-1<index $output,'4.0.950') {
      return 'Windows 95';
   } elsif (-1<index $output,'4.0.950') {
      return 'Windows 98';
   } elsif (-1<index $output,'4.10.2222') {
      return 'Windows 98 SE';
   } elsif (-1<index $output,'4.90.3000') {
      return 'Windows ME';
   } elsif (-1<index $output,'NT') {
      return 'Windows NT';
   } elsif (-1<index $output,'5.0.2195') {
      return 'Windows 2000';
   } elsif (-1<index $output,'5.1.2600') {
      return 'Windows XP';
   } elsif (-1<index $output,'5.2.3790') {
      return 'Windows Server 2003';
   } elsif (-1<index $output,'5.2.4500') {
      return 'Windows Home Server'; # aka Windows XP 64-Bit Edition
   } elsif (-1<index $output,'6.0.6001') {
      return 'Windows Vista';
   } elsif (-1<index $output,'6.0.6002') {
      return 'Windows Server 2008';
   } elsif (-1<index $output,'6.1.7600') {
      return 'Windows Server 2008 R2'
   } elsif (-1<index $output,'6.1.7601') {
      return 'Windows 7 SP1';
   } else {
      $output=~s/\s*\[.*$//s;
      return $output;
   }
}

if ($^O eq 'cygwin' && &windows_ver=~/XP|2000|NT/) {
   my $regc='regtool -v check "/HKLM/Software/Microsoft/'.
            'Windows/CurrentVersion/Explorer/AlwaysUnloadDLL" 2>&1';
   my $outp=`$regc`;
   my $notthere=0;
   if ($outp=~/key\s+exists/s) {
      my $regc='regtool -v list "/HKLM/Software/Microsoft/'.
            'Windows/CurrentVersion/Explorer/AlwaysUnloadDLL" 2>&1';
      my $outp=`$regc`;
      if ($outp!~/\(REG_SZ\) = \"1\"/) {
         $notthere=1; 
      }
   } else { $notthere=1 }
   if ($notthere) {
      {
         local $SIG{__DIE__}; # No sigdie handler
         eval {
            my $timeout=120;
            local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
            alarm $timeout;
            print "\n       *** THIS SCREEN WILL TIMEOUT IN 2 MINUTES ***\n".
                  "\n       IMPORTANT! : FullAuto is VERY Memory Intensive.".
                  "\n                  Setup has detected that a recommended".
                  "\n                  Windows XP registry setting does NOT".
                  "\n                  exist. As a result, Windows XP does".
                  "\n                  not remove DLL's from memory when an".
                  "\n                  an application exits, but keeps them".
                  "\n                  in memory for a time in order to speed".
                  "\n                  up application startup *in case* the".
                  "\n                  the app is restarted. Cygwin and ssh".
                  "\n                  load DLLs and with repeated invocation".
                  "\n                  (which is common FullAuto usage),".
                  "\n                  memory can 'max' out and cause all".
                  "\n                  active FullAuto and Cygwin processes".
                  "\n                  to freeze and hang.".
                  "\n\n       Therefore, it is *HIGHLY* recommended that this".
                  "\n       registry setting exist:\n".
                  "\n       /HKLM/Software/Microsoft/Windows/CurrentVersion/".
                  "Explorer/AlwaysUnload DLL\n".
                  "\n       FullAuto setup can do this for you, but only with".
                  "\n       your approval. Would you like FullAuto setup to".
                  "\n       attempt to insert this registry setting?".
                  "\n\n       (If you do not wish FullAuto setup to".
                  "\n       perform this step, type 'N' and setup will".
                  "\n       continue WITHOUT modifying the Windows registry.)".
                  "\n\n";
            print "Type <Y> if you wish to FullAuto setup to modify ",
                  "the registry,\nor 'N' to proceed without this step ",
                  ". . . [N] ";
            $a=<STDIN>;
            alarm 0;
         };
         if ($@) {
            # timed out
            # exit;
         } elsif ($a=~/^[Yy]$/s) {
            $regc='cmd /c "REG ADD HKLM\\Software\\Microsoft\\Windows\\'.
                  'CurrentVersion\\Explorer\\AlwaysUnloadDLL '.
                  '/ve /t REG_SZ /d 1" 2>&1';
            $outp=`$regc`;
            print $outp."\n";
         } alarm 0;
      };
   }
}

#Specific dependencies for web caching functionality
#requires        'Cache::Cache'              => 0;
#requires        'CHI'                       => 0;

auto_install();

my $c_file='';
my $date=strftime('%D',localtime);

my $banner='';my $perllibdir='';my $perlsitebin='';
if (exists $ENV{PERL_LOCAL_LIB_ROOT}) {
   $perllibdir=$ENV{PERL_LOCAL_LIB_ROOT};
   $perlsitebin=$ENV{PERL_LOCAL_LIB_ROOT}.'/bin';
} else {
   unless (-e $Config{installsitelib}) {
      `mkdir -p $Config{installsitelib}`;
   }
   unless (-w $Config{installsitelib}) {
      $banner="\n   ".
           "*** THIS SCREEN WILL TIMEOUT AND CHOOSE 'NO' IN 2 MINUTES ***\n".
           "\n   WARNING!: You do not have permission to install FullAuto".
           "\n   to the default location -> $Config{installsitelib}.\n".
           "\n   Hint 1: You can use the PREFIX and LIB attributes to".
           "\n   set several attributes at once. The quickest way to".
           "\n   install FullAuto in a non-default location might be".
           "\n   setting PREFIX to '~'. You can do this by selecting".
           "\n   'Yes' below, or by re-running Makefile.PL with the".
           "\n   the following argument:\n".
           "\n   perl Makefile.PL PREFIX=~\n".
           "\n   This will install all FullAuto files under your home".
           "\n   directory, with man pages and libraries going into the".
           "\n   appropriate place (most likely ~/man and ~/lib)\n".
           "\n   You may also consider using the LIB attribute:\n".
           "\n   perl Makefile.PL LIB=~/lib\n".
           "\n   See the MakeMaker.pm module documetation for more".
           "\n   information:\n".
           "\n   http://search.cpan.org/~mschwern/ExtUtils-MakeMaker-6.56".
           "/lib/ExtUtils/MakeMaker.pm#PREFIX_and_LIB_attribute\n".
           "\n   Hint 2: Run perl MakeMaker.PL with an appropriate user".
           "\n   (such as root) or with a utility such as sudo if you".
           "\n   are authorized to use it (sudo perl Makefile.PL).".
           "\n   The same is true if you are attempting to install".
           "\n   FullAuto via the CPAN resposiory (i.e. 'sudo cpan')\n".
           "\n   Would like to install FullAuto to your home (~) directory?\n\n"
   }
   $perllibdir=$Config{installsitelib};
   $perlsitebin=$Config{installsitebin};
}

if ($banner) {

   my $timeout=120;my $selection='';
   {
      local $SIG{__DIE__}; # No sigdie handler
      eval {
         local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
         alarm $timeout;
         my $menu1 = [
                     $banner,
                     [ "Yes", sub{ return 'Yes' } ],
                     [ "No   (FullAuto install will exit)",
                       sub{ return 'No' } ],
                     #[ "Quit", sub {exit;} ],
                     ];
         $selection=&menu($menu1);
         exit if $selection eq ']quit[';
         alarm 0;
      };
      if ($@) {
         # timed out
         $selection = 'No';
      }
      if ($selection=~/No/) {
         exit;
      } alarm 0;
   };
}

print "$cwd\n";
chdir $cwd;

open(FH,">fullauto.c");

print FH '/* program: fullauto'."\n".
"   author:  Brian Kelly\n".
"   date:    $date\n".
"\n".
"   purpose: C program wrapper that calls $perlsitebin/fullauto.pl script\n".
"   WARNING: This file is auto-generated by Makefile.PL, please change Makefile.PL.\n".
"            Any modifications made to this source file will be lost!\n".
'*/'."\n".
"\n".
'#define REAL_PL '.'"'.$perlsitebin."/fullauto.pl\"\n".
"main(int argc, char *argv[])\n".
'{'."\n".
"\tsetuid(0);\n".
"\tseteuid(0);\n".
"\texecv(REAL_PL, argv);\n".
'}'."\n";

close FH;

my $timeout=120;my $selection='';
if (keys %amazon) {
   $selection='Install with 777 Permissions on FullAuto Files Only (Default)';
} elsif (!exists $ENV{FA_BERKELEY}) {
   {
      local $SIG{__DIE__}; # No sigdie handler
      eval {
         local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
         alarm $timeout;
         my @list=();
         my %perms_menu=();
         unless ($^O eq 'cygwin') {
            @list=('Install with 777 Permissions on FullAuto Files Only (Default)',
                   'Install with Setuid Permissions (Experimental)',
                   'Install with Setgid Permissions (Experimental)',
                   'Install with 770 Permissions on FullAuto Files Only (Experimental)'
                  );
            my $banner="\n   *** THIS SCREEN WILL TIMEOUT AND CHOOSE ".
                  "\'777 Permissions\' IN 2 MINUTES ***\n".
                  "\n   Choose a Permission Setting :\n\n";
            %perms_menu=(

               Name => 'perms_menu',
               Item_1 => {

                  Text => ']C[',
                  Convey => \@list,

               },
               Scroll => 1,
               Banner => $banner,

            ); 
         } else {
            @list=("Install with 777 Permissions on FullAuto Files Only (Default)\n\n",
                   'Install with 770 Permissions on FullAuto Files Only (Experimental)'
                  );
            my $banner="\n   *** THIS SCREEN WILL TIMEOUT AND CHOOSE ".
                   "\'777 Permissions\' IN 2 MINUTES ***\n".
                   "\n   Choose a Permission Setting :\n\n";
            %perms_menu=(

               Name => 'perms_menu',
               Item_1 => {

                  Text => ']C[',
                  Convey => \@list,

               },
               Scroll => 1,
               Banner => $banner,

            );
         }
         $selection=Term::Menus::Menu(\%perms_menu);
         alarm 0;
      };
      exit if $selection eq ']quit[';
      if ($@) {
         # timed out
         print "\n";
         $selection = '777 Permissions';
         Term::ReadKey::ReadMode(0);
      } alarm 0;
   };
} elsif (-1<index $ENV{FA_BERKELEY},'770 Permissions') {
   $selection='Install with 770 Permissions on FullAuto Files Only (Experimental)';
} elsif (-1<index $ENV{FA_BERKELEY},'777 Permssions') {
   $selection='Install with 777 Permissions on FullAuto Files Only (Default)';
}

my $permission = '777 Permissions';
if (-1<index $selection,'Setuid') {
   $permission = 'Setuid';
} elsif (-1<index $selection,'Setgid') {
   $permission = 'Setgid';
} elsif (-1<index $selection,'770 Permissions') {
   $permission = '770 Permissions';
   $cygwin_berkeley_db_mode=770 if $^O eq 'cygwin';
} elsif (-1<index $selection,'777 Permissions') {
   $permission = '777 Permissions';
   $cygwin_berkeley_db_mode=777  if $^O eq 'cygwin';
} elsif (-1<index $selection,'quit') {
   exit;
} print "\n";

if ($^O eq 'cygwin') {
   open(FH,">bin/fullauto.exe");
   print FH "\n";
   close FH;
   install_script('bin/fullauto.exe');
   install_script('bin/install_mozrepl_plugin.exe');
   unlink "bin/fullauto.exe";
   &install_firefox() if -1<index $install_firefox,'Install';
} else {
   open(FH,">bin/fullauto");
   print FH "\n";
   close FH;
   install_script('bin/fullauto');
   unlink "bin/fullauto";
}
install_script('bin/fullauto.pl');

my $good_choice=<<'END';

     ___               _     ___ _        _        _ 
    / __| ___  ___  __| |   / __| |_  ___(_)__ ___| |
   | (_ |/ _ \/ _ \/ _` |  | (__| ' \/ _ \ / _/ -_)_|
    \___|\___/\___/\__,_|   \___|_||_\___/_\__\___(_)


   The Nano Editor is widely considered to be the easiest Terminal Editor to
   learn. Here are a couple of important things to remember. When you look at
   at the bottom of the screen, you will see character combinations like this:

   ^E ^W ^O  -->  the caret symbol (for Ctrl key) followed by a letter.

   Ctrl key is pressed with letter next to it. For example, to exit Nano (^E)
    ________     ____                    _______     ____ 
   || Ctrl ||   ||E ||                  || Alt ||   ||C ||
   ||______|| + ||__||  M-C  is  alt c  ||_____|| + ||__||
   |/______\|   |/__\|                  |/_____\|   |/__\|

END

my $nano_banner=<<END;

   .e.f8 ee.     88**8.  e888 88**8. .d88b.   GNU
   i '8f'  Q,    88  88 88 88 88  88 88  88
      8.   8:    88  88 "t888 88  88 "t88P"   Text Editor
      8.   8:
      W.   8:    In Terminal Environments, Documentation
           8:    for Nano can be seen anytime by typing:
           8:    
           tD    man nano    at the command line.


   You can also see online documentation at:

   http://www.nano-editor.org/docs.php
END

my $learn_nano=sub {

   my %learn_nano=(

      Name => 'learn_nano',
      Item_1 => {

         Text => "Go to Nano man page (type q to return)",
         Result => sub { system('man nano');return '<' },

      },
      Item_2 => {

         Text   => "Launch and explore Nano (type ctrl + e to return)",
         Result => sub { system('nano');return '<' },

      },
      Item_3 => {

         Text => "Continue Installing FullAuto",

      },
      Scroll => 3,
      Banner => $nano_banner,

   );
   return \%learn_nano;

};

my $goodchoice=sub {

   my %goodchoice=(

      Name => 'goodchoice',
      Item_1 => {

         Text   => "Learn more about Nano",
         Result => $learn_nano, 

      },
      Item_2 => {

         Text   => "Continue Installing FullAuto",

      },
      Scroll => 2,
      Banner => $good_choice,

   );
   return \%goodchoice;

};

sub old_cpan { 
   foreach my $inc (@INC) {
      if (-e $inc.'/CPAN/Config.pm') {
         unless (-e $inc.'/CPAN/SQLite.pm') { 
            my $cmd='sed -i \'s/^\\(.*use_sqlite.*q\\).*$/'.
                    '\\1[0],/\''." $inc/CPAN/Config.pm";
            `$cmd` || print $!;
         }
         return 1;
      }
   }
}

sub fa_system {
   open(CH,"$_[0]|") || return 1;
   CH->autoflush;
   while (my $line=<CH>) {
      if (-1<index $line,"Can't connect to") {
         close CH;
         return 1;
      }
      print $line;
   }
   close CH;
}

sub fa_die {
   my $message=$_[0];
   print STDERR $message;
   if (exists $ENV{PAR_TEMP}) {
      print $log $message if $log;
      print "   PRESS ANY KEY to Exit Setup\n\n";
      <STDIN>;
   } exit 1
}

sub fa_editor_mswin {

   # http://pen-testing.sans.org/blog/2012/06/06/ \
   # escaping-restricted-linux-shells/comment-page-1/
   my @editors=('vim     ( ViIMproved - enhanced vi editor )',
                'nano    ( Easiest - Recommended for Beginners )',
                "emacs   ( The extensible, customizable,\n           ".
                "               self-documenting real-time\n         ".
                '                display editor )',
                "joe     ( Fast and simple editor that\n             ".
                '             emulates 5 other editors )',
               );
   my $tp='';my $selection='';
   unless ($tp=&fa_find_editor('TextPad.exe')) {
      if (-e ${ENV}{SystemDrive}.
            "\\Program Files\\TextPad 5\\TextPad.exe") {
         $tp='default';
      }
   }
   if ($tp) {
      push @editors, 'TextPad (The Text Editor for Windows)';
   }
   my $banner=<<'END';
    ___      _        _      ___    _ _ _
   / __| ___| |___ __| |_   | __|__| (_) |_ ___ _ _
   \__ \/ -_) / -_) _|  _|  | _|/ _` | |  _/ _ \ '_|
   |___/\___|_\___\__|\__|  |___\__,_|_|\__\___/_|


   In order to use the integrated edit features you will need to choose
   an editor. 'vim' (or 'vi') is set as the default - but it is
   recommended you try 'nano' if you do not know the vim or vi editor.


END
   my %Menu_select_editor=();
   if (-e ${ENV}{SystemDrive}.
         "\\Program Files\\Windows NT\\Accessories\\wordpad.exe") {
      %Menu_select_editor=(

            Label  => 'Menu_select_editor',
            Item_1 => {

               Text    => "]C[",
               Convey  => \@editors,

            },
            Item_2 => {

               Text => "Wordpad (Microsoft Wordpad -\n               ".
                       "        Available on all Windows Systems)",

            },
            Scroll => 1,
            Banner => $banner,

      );
   } else {
      %Menu_select_editor=(

            Label  => 'Menu_select_editor',
            Item_1 => {

               Text    => "]C[",
               Convey  => \@editors,

            },
            Scroll => 1,
            Banner => $banner,

      );
   }

   if ($install_cygwin_without_asking) {
      my $look_for_wordpad=${ENV}{SystemDrive}.
            "\\Program Files\\Windows NT\\Accessories\\wordpad.exe";
      if (-e $look_for_wordpad) {
         $selection='wordpad';
         my $sysdr=`cmd /c echo %SystemDrive%`;
         $sysdr=~s/^\s*(.*)\s*$/$1/s;
         my $let=substr($sysdr,0,1);
         my $lt=lc($let);
         $editor='/cygdrive/'.$lt.'/Program Files/Windows NT/'.
                 'Accessories/wordpad.exe';
      }
   } elsif (0<$#editors) {
      $selection=Term::Menus::Menu(\%Menu_select_editor);
      chomp($selection);
      exit if $selection eq ']quit[';
   } elsif (0==$#editors) {
      $selection=$editors[0];
   }
   if ($selection=~/([Ww]ordpad)/) {
      $selection=$1;
      my $sysdr=`cmd /c echo %SystemDrive%`;
      $sysdr=~s/^\s*(.*)\s*$/$1/s;
      my $let=substr($sysdr,0,1);
      my $lt=lc($let);
      $editor='/cygdrive/'.$lt.
         '/Program Files/Windows NT/Accessories/wordpad.exe';
   } elsif ($selection=~/(TextPad)/) {
      $selection=$1;
      if ($tp eq 'default') {
         my $sysdr=`cmd /c echo %SystemDrive%`;
         $sysdr=~s/^\s*(.*)\s*$/$1/s;
         my $let=substr($sysdr,0,1);
         my $lt=lc($let);
         $editor='/cygdrive/'.$lt.
            '/Program Files/TextPad 5/TextPad.exe';
      } else {
         $tp=~s/\\/\//g;
         $tp=~s/^([A-Za-z]):(.*)/$1$2/;
         $editor='/cygdrive/'.$tp;
      }
   } elsif ($selection=~/(vim)/) {
      $selection=$1;
      $editor='/bin/vim.exe';
   } elsif ($selection=~/(emacs)/) {
      $selection=$1;
      $editor='/bin/emacs.exe';
   } elsif ($selection=~/(joe)/) {
      $selection=$1;
      $editor='/bin/joe.exe';
   } elsif ($selection=~/(nano)/) {
      $selection=$1;
      $editor='/bin/nano.exe';
   }
   return $selection,$editor;

}

sub fa_web_api {

   my $api_banner=<<'END';

    ___         _        _ _   __      __   _         _   ___ ___ ___
   |_ _|_ _  __| |_ __ _| | |  \ \    / /__| |__     /_\ | _ \_ _|__ \
    | || ' \(_-<  _/ _` | | |   \ \/\/ / -_) '_ \   / _ \|  _/| |  /_/
   |___|_||_/__/\__\__,_|_|_|    \_/\_/\___|_.__/  /_/ \_\_| |___|(_)


   The FullAuto core installation is a command shell environment utility.
   In this configuration, EVERYTHING can be automated via scripts written
   in the Perl scripting language.

   With the Web API option, FullAuto worker processes with persistent
   connections to remote hosts are fully accessible in *ANY* programming
   or scripting language. The FullAuto Web API is secured via OAuth 2.0
   tokens and is a RESTful/JSON implementation.


END

   my $what_to_expect=<<'END';

   __      ___         _      _          ___                  _
   \ \    / / |_  __ _| |_   | |_ ___   | __|_ ___ __  ___ __| |_
    \ \/\/ /| ' \/ _` |  _|  |  _/ _ \  | _|\ \ / '_ \/ -_) _|  _|
     \_/\_/ |_||_\__,_|\__|   \__\___/  |___/_\_\ .__/\___\__|\__|
                                                |_|

   The FullAuto base install can take just ten minutes on a top tier cloud
   server, or an hour or more on a mini host like an Amazon EC2 Free-Tier
   t2.micro server. This is due to multiple factors such as network
   bandwidth, CPU speed and memory capacity of the target host.

   If you elected to install the Web API, you are likely to DOUBLE the
   overall installation time. A total of 20-30 minutes on a top tier host,
   to as long as 3 hours or more for a micro server during peak traffic
   periods - especially on Windows hosts (which have an additional Cygwin
   dependency).

   FullAuto and the FullAuto Web API have numerous dependencies that
   all take time to download, build and configure. A short list is
   BerkeleyDB, Catalyst MVC Application Server, and ZeroMQ Messaging.

END

   my $expectations={

      Name => 'expectations',
      Result => sub { my $return="]P[";return $return },
      Banner => $what_to_expect,

   };

   my $which_install={

      Name => 'which_install',
      Item_1 => {

         Text => "Install Base FullAuto and the FullAuto Web API\n\n",
         Result => $expectations,

      },
      Item_2 => {

         Text => "Install Base FullAuto Only\n\n",
         Result => $expectations,

      },
      Scroll => 1,
      Banner => $api_banner,

   };
   my $selection=Term::Menus::Menu($which_install);
   $selection=~s/^["](.*)["]$/$1/s;
   $selection=~s/\s*$//s;
   return $selection;

}

sub fa_license {

   my %read_license=(

      Name => 'read_license',
      Item_1 => {
         Text => "I accept the license provisions",
      },
      Item_2 => {
         Text => "I do *NOT* accept the license provisions ".
                 "(Install will Exit)",
      },
      Item_3 => {
         Text => "Review GNU Affero Public License Version 3\n".
                 "                   in its entirety".
                 " (type 'q' to return)",
         Result => sub {

            if (exists $ENV{PAR_TEMP}) {
               system("$ENV{PAR_TEMP}\\inc\\tools\\less.exe ".
                      "$ENV{PAR_TEMP}\\inc\\LICENSE");
            } else {
               system('less LICENSE');
            } return '<'
         },
      },
      Item_4 => {
         Text => "Return to previous screen",
         Result => sub { return '{license_agree}<' },
      },
      Scroll => 1,
      Banner => sub {

            my $linenumber="]P[";
            $linenumber||=1;
            $linenumber=~s/["]//g;
            my $dir='';
            $dir="$ENV{PAR_TEMP}/inc/" if exists $ENV{PAR_TEMP};
            open (FH,"<${dir}LICENSE")
               or die "Cannot open ${dir}LICENSE: $!\n";
            my @content=<FH>;
            close FH;
            my $co=$#content+1;
            my $endcount=(13<$co)?13:$co;
            if (-1==index $linenumber,'Review') {
               if ($linenumber=~/Next|Previous/) {
                  $linenumber=~s/^(?:Next|Previous) Page\s*//;
               }
               ($linenumber,$endcount)=split '-', $linenumber;
               my $tl=$#content+1;
               my $lt=$linenumber+13;
               $endcount=($lt<$tl)?$lt:$tl;
            } elsif (-1<index $linenumber,'WARRANTY') {
               $linenumber=588;
               $endcount=597;
            } else { $linenumber=1 }
            $linenumber=0 if $linenumber==1;
            --$endcount;
            my $banner=join "", @content[$linenumber..$endcount];
            $banner=~s/^/   /mg;
            return $banner;

      }

   );

   my $cryptography_banner=<<'END';
   __      __             _           _ 
   \ \    / /_ _ _ _ _ _ (_)_ _  __ _| |
    \ \/\/ / _` | '_| ' \| | ' \/ _` |_|
     \_/\_/\__,_|_| |_||_|_|_||_\__, (_)
                                |___/  

   Exporting, importing and/or using cryptography software, or even
   communicating technical details about cryptography software, is illegal
   in some parts of the world. You are strongly advised to investigate and
   adhere to any export/import and use laws which apply to you when you
   import a release of Net::FullAuto including cryptography modules like
   Crypt::CBC, Crypt::DES and Crypt::Rijndael to your country or
   re-distribute source code from them in any way.
END

   my $cryptography=sub {

      my %cryptography=(

         Name => 'cryptography',
         Result => sub { return '{license_agree}<' },
         Banner => $cryptography_banner,      

      );
      return \%cryptography

   };

   my $license_banner=<<END;

   *THANK YOU* For Trying FullAuto!   Net::FullAuto INSTALLATION PROGRAM

   Copyright (C) 2000-2019   Brian M. Kelly   Brian.Kelly\@FullAuto.com

   This program comes with ABSOLUTELY NO WARRANTY; for details select 2.
   This is free software, and you are welcome to redistribute it under certain
   conditions. Select 2 for full license. FullAuto uses  Crypt::DES  which is
   software developed by Systemics Ltd (http://www.systemics.com/). FullAuto
   uses the  Net::SSLeay  module which is software developed by the OpenSSL
   Project for use in the OpenSSL Toolkit. (http://www.openssl.org/) and
   includes cryptographic software written by Eric Young (eay\@cryptsoft.com)
   and Tim Hudson (tjh\@cryptsoft.com)

END

   my %license_agree=(

      Name => 'license_agree',
      Item_1 => {

         Text => "I agree to the license provisions\n\n",

      },
      Item_2 => {

         Text => "Review GNU Affero Public License WARRANTY DISCLAIMER\n",
         Result => \%read_license,
      },
      Item_3 => {

         Text => "*IMPORTANT* STRONG CRYPTOGRAPHY WARNING!",
         Result => $cryptography,

      },
      Item_4 => {

         Text => "I DO NOT AGREE to the license provisions\n".
                 "                   ( FullAuto Install will EXIT )",
      },
      Scroll => 1,
      Banner => $license_banner,

   );
   my $lic_sel='';
   if (!(exists $ENV{PERL5_CPAN_IS_RUNNING}
         && $ENV{PERL5_CPAN_IS_RUNNING}) ||
         exists $ENV{PAR_TEMP}) {
      $lic_sel=Menu(\%license_agree);
      chomp($lic_sel);
      exit if $lic_sel eq ']quit[';
      if (-1<index $lic_sel, 'NOT') {
         my $exitmsg=<<END;

   You have elected *NOT* to install FullAuto.
   Please report any bugs and send any
   questions, thoughts or feedback to:

      Brian.Kelly\@FullAuto.com.

END
         print $exitmsg;
         if (exists $ENV{PAR_TEMP}) {
            print "   Press ANY key to exit.\n\n";<STDIN>;
         }
         exit;
      }
   }

}

WriteAll();

if (keys %amazon) {
   fa_system('sudo make install');
   if (exists $amazon{argv}) {
      my $p=$amazon{argv}->[0];
      my $username=getlogin || getpwuid($<);
      select STDOUT;
      $log->close() if $log && -1<index $log,'*';
      exec "/usr/local/bin/fa",'-i',$p,
           '--iset-amazon','--login',
           $username,'--log';
   }
}

sub fa_find_editor {
   my $editor=$_[0];
   $editor=~s/^.*\///;
   $editor=~s/[.]exe$//;
   return 0 unless $editor;
   foreach my $path (split ':', $ENV{PATH}) {
      $path=~s/[\/]*$/\//;
      if ($^O eq 'cygwin' && (-e $path.$editor.'.exe')) {
         return $path.$editor.'.exe';
      } elsif (-e $path.$editor) {
         return $path.$editor;
      }
   } return 0;
}

package MY; # so that "SUPER" works right

sub MY::top_targets {

   my $inherited = shift->SUPER::top_targets(@_);

   $inherited =~ s/pure_all :: /pure_all :: fullauto\$(EXE_EXT) /;
   $inherited =~ s/ linkext//;

   $inherited; #

}

sub MY::makefile {

   use Config;

   my $inherited = shift->SUPER::makefile(@_);

   $inherited .= "fullauto\$(EXE_EXT): fullauto.c\n\t\$(CC) fullauto.c -o \$@".
                 "\n\t\$(CP) \$@ bin\n\n";

   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_host.pm") {
      $inherited .= "lib/Net/FullAuto/Custom/fa_host.pm:".
                    "\n\tmkdir -p blib/lib/Net/FullAuto/Custom 2>&1".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_host.pm \$@".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_host.pm ".
                    "blib/\$@\n\n";
   } else {
      $inherited =~ s/^(.*FullAuto.*fa_host.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/fa_host.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/fa_host.pm";
      unlink "blib/lib/Net/FullAuto/Custom/fa_host.pm";
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") {
      $editor=~s/\//\\\//g;
      $inherited .= "lib/Net/FullAuto/Custom/fa_conf.pm:".
                    "\n\tmkdir -p blib/lib/Net/FullAuto/Custom 2>&1".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_conf.pm \$@".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_conf.pm ".
                    "blib/\$@\n\n";
   } else {
      $inherited =~ s/^(.*Custom\/fa_conf.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/fa_conf.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/fa_conf.pm";
      unlink "blib/Net/FullAuto/Custom/fa_conf.pm";
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_menu.pm") {
      $inherited .= "lib/Net/FullAuto/Custom/fa_menu.pm:".
                    "\n\tmkdir -p blib/lib/Net/FullAuto/Custom 2>&1".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_menu.pm \$@".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_menu.pm ".
                    "blib/\$@\n\n";
   } else {
      $inherited =~ s/^(.*Custom\/fa_menu.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/fa_menu.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/fa_menu.pm";
      unlink "blib/lib/Net/FullAuto/Custom/fa_menu.pm";
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_code.pm") {
      $inherited .= "lib/Net/FullAuto/Custom/fa_code.pm:".
                    "\n\tmkdir -p blib/lib/Net/FullAuto/Custom 2>&1".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_code.pm \$@".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_code.pm ".
                    "blib/\$@\n\n";
   } else {
      $inherited =~ s/^(.*Custom\/fa_code.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/fa_code.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/fa_code.pm";
      unlink "blib/lib/Net/FullAuto/Custom/fa_code.pm";
   }
   if (-1<index $install_firefox,'Install') {
      my $cygwin_loc=get_cygwin_location(1);
      $cygwin_loc=~s/\\/\//;
      $inherited .= "$Config{installsitelib}/Net/FullAuto/$mozrepl_file:".
                    "\n\t\$(CP) $cygwin_loc/$mozrepl_file \$@\n\n";
   }

   $inherited; #

}

sub MY::dist {

   use Config;

   my $inherited = shift->SUPER::dist(@_);

   if (grep { /-*add[-_]?dependencies/i } @ARGV) {

      $inherited =~ s/^(DISTVNAME.*Net-FullAuto)(.*)$/$1-Complete$2/m;

   }

   $inherited; #

}

sub MY::tools_other {

   use Config;

   my $inherited = shift->SUPER::tools_other(@_);

   $inherited =~
      s/^MV.*$/MV = mv -f/m;

   $inherited =~
      s/^(MV.*)$/$1\nSED = sed/m;

   $inherited; #

}

sub MY::constants {

   use Config;

   my $inherited = shift->SUPER::constants(@_);

   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_host.pm") {
      my $fa_h="\tlib\/Net\/FullAuto\/Custom\/fa_host.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/fa_host.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/fa_host.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/fa_host.pm \\/m; 
      $inherited =~
         s/(\s+blib.*Distro\/fa_host.pm \\)/$1\n$fa_h/m;
   } else {
      $inherited =~ s/^(.*Custom\/fa_host.pm.*)$//;
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") {
      my $fa_g="\tlib\/Net\/FullAuto\/Custom\/fa_conf.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/fa_conf.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/fa_conf.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/fa_conf.pm \\/m;
      $inherited =~
         s/(\s+blib.*Distro\/fa_conf.pm \\)/$1\n$fa_g/m;
   } else {
      $inherited =~ s/^(.*Custom\/fa_conf.pm.*)$//;
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_menu.pm") {
      my $fa_m="\tlib\/Net\/FullAuto\/Custom\/fa_menu.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/fa_menu.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/fa_menu.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/fa_menu.pm \\/m;
      $inherited =~
         s/(\s+blib.*Distro\/fa_menu.pm \\)/$1\n$fa_m/m;
   } else {
      $inherited =~ s/^(.*Custom\/fa_menu.pm.*)$//;
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_code.pm") {
      my $fa_c="\tlib\/Net\/FullAuto\/Custom\/fa_code.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/fa_code.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/fa_code.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/fa_code.pm \\/m;
      $inherited =~
         s/(\s+blib.*Distro\/fa_code.pm \\)/$1\n$fa_c/m;
   } else {
      $inherited =~ s/^(.*Custom\/fa_code.pm.*)$//;
   }

   $inherited =~ 
      s/(PERM_RWX = \d+)/$1\nPERM_S_X = 4511\nPERM_G_X = 2551/m;
   $inherited =~
      s/(PERM_G_X = \d+)/$1\nPERM_S+X = 4555\n/m;
   $inherited =~
      s/(PERM_S[+]X = \d+)/$1\nPERM_R+X = 555\nPERM_R-X = 550\nPERM_R_X = 511/m;
   $inherited =~
      s/(PERM_R_X = \d+)/$1\nPERM_D-X = 750\nPERM_D_X = 700\nPERM_WRX = 777/m;
   $inherited =~
      s/(PERM_WRX = \d+)/$1\nPERM_OG_ = 770/m;
   if ($^O eq 'cygwin') {
      $inherited =~
         s#^INSTALL_BASE.*$#INSTALL_BASE = /usr/lib/perl5#m;
   }

   $inherited; #

}

sub MY::dynamic_bs {

   my $inherited = shift->SUPER::installbin(@_);

   $inherited =~ s/^.*//s;

   $inherited; #

}

sub MY::dynamic {

   my $inherited = shift->SUPER::installbin(@_);

   $inherited =~ s/^.*//s;

   $inherited; #

}

sub MY::installbin {

   my $inherited = shift->SUPER::installbin(@_);

   $inherited =~ s/RM_F\) \\/RM_F\) bin\/fullauto\$(EXE_EXT) fullauto.c fullauto\$(EXE_EXT)\\/;

   $inherited =~ s/RM_F\) \$\(INST_SCRIPT\)\/fullauto.exe/RM_F\) \$\(INST_SCRIPT\)\/fullauto.exe\n\t\$\(CHMOD\) 755 bin\/fullauto\$\(EXE_EXT\)/s;

   $inherited; #

}

sub MY::install {

   use Config;
   my $inherited = shift->SUPER::install(@_);

   if ($permission eq 'Setuid') {
      $inherited =~ s/(install ::.*)$/$1 setuid_permissions/m;
   } elsif ($permission eq 'Setgid') {
      $inherited =~ s/(install ::.*)$/$1 setgid_permissions/m;
   } elsif ($permission eq '770 Permissions') {
      if (-1<index $install_firefox,'Install') {
         my $mz="$Config{installsitelib}/Net/FullAuto/$mozrepl_file";
         $inherited =~
            s/(install ::.*)$/$1 owner_group_permissions $mz/m;
      } else {
         $inherited =~ s/(install ::.*)$/$1 owner_group_permissions/m;
      }
   } else {
      if (-1<index $install_firefox,'Install') {
         my $mz="$Config{installsitelib}/Net/FullAuto/$mozrepl_file";
         $inherited =~
            s/(install ::.*)$/$1 full_access_permissions $mz/m;
      } else {
         $inherited =~ s/(install ::.*)$/$1 full_access_permissions/m;
      }
   }

   if (-e '/usr/share/figlet') {
      $inherited =~ s/(install ::.*)$/$1 figlet_fonts/m;
   }

   my $link='';
   my $lnpath='';
   if (-e "/bin/ln") {
      $lnpath="/bin/ln";
   } elsif (-e "/usr/bin/ln") {
      $lnpath="/usr/bin/ln";
   } elsif (-e "/usr/local/bin/ln") {
      $lnpath="/usr/local/bin/ln";
   }

   if ($lnpath) {
      $link="\t\$(NOECHO) $lnpath -f -s ".
            "\$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT) ".
            "\$(DESTINSTALLSITESCRIPT)\/fa\n"; 
   }

   $inherited .= "\nsetuid_permissions ::\n".
     "\t\$(NOECHO) \$(ECHO) \"Applying Setuid Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_S+X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_D_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
      $link;
   $inherited .= "\nsetgid_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying Setgid Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_G_X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_D-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
      $link;
   $inherited .= "\nowner_group_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying 770 Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_OG_) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_OG_) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/Custom\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_OG_) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/Custom\/*\n".
      $link.
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_OG_) /var\n".
      "\t\$(NOECHO) if [ -d /var/db ];".
      "then \$(CHMOD) \$(PERM_OG_) /var/db; fi\n";
      "\t\$(NOECHO) if [ -d /var/db/Berkeley ];".
      "then \$(CHMOD) \$(PERM_OG_) /var/db/Berkeley; fi\n";
      "\t\$(NOECHO) if [ -d /var/db/Berkeley/FullAuto ];".
      "then \$(CHMOD) \$(PERM_OG_) /var/db/Berkeley/FullAuto; fi\n";
   $inherited .= "\t\$(SED) \'s/^[ ]*our[ ]*\\(.\\)".
      "cygwin_berkeley_db_mode[ ]*[=].*/".'our \\1'.
      "cygwin_berkeley_db_mode = \$(PERM_OG_);/g\' ".
      "\$(DESTINSTALLSITELIB)/Net/FullAuto/FA_Core.pm >tmp_fa_core.pm\n".
      "\t\$(MV) ./tmp_fa_core.pm \$(DESTINSTALLSITELIB)".
      "/Net/FullAuto/FA_Core.pm\n"
      if $^O eq 'cygwin';
   $inherited .= "\nfull_access_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying 777 Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_WRX) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_WRX) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/Custom\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_WRX) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/Custom\/*\n".
      $link.
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_WRX) /var\n".
      "\t\$(NOECHO) if [ -d /var/db ];".
      "then \$(CHMOD) \$(PERM_WRX) /var/db; fi\n";
      "\t\$(NOECHO) if [ -d /var/db/Berkeley ];".
      "then \$(CHMOD) \$(PERM_WRX) /var/db/Berkeley; fi\n";
      "\t\$(NOECHO) if [ -d /var/db/Berkeley/FullAuto ];".
      "then \$(CHMOD) \$(PERM_WRX) /var/db/Berkeley/FullAuto; fi\n";
   $inherited .= "\t\$(SED) \'s/^[ ]*our[ ]*\\(.\\)".
      "cygwin_berkeley_db_mode[ ]*[=].*/".'our \\1'.
      "cygwin_berkeley_db_mode = \$(PERM_WRX);/g\' ".
      "\$(DESTINSTALLSITELIB)/Net/FullAuto/FA_Core.pm >tmp_fa_core.pm\n".
      "\t\$(MV) ./tmp_fa_core.pm \$(DESTINSTALLSITELIB)".
      "/Net/FullAuto/FA_Core.pm\n"
      if $^O eq 'cygwin';
   $inherited .= "\nfiglet_fonts ::\n".
      "\t\$(NOECHO) \$(CP) dependencies/FIGlet_fonts/* /usr/share/figlet";

   $inherited; #

}

sub MY::dist_core {

   my $inherited = shift->SUPER::dist_core(@_);

   $inherited =~ s/tar$/tar\n\t\$(MV) \$(DISTVNAME).tar\$(SUFFIX) dist/m;

   $inherited; #

}

sub MY::clean {

   my $inherited = shift->SUPER::clean(@_);

   $inherited =~ s/blib\s*$/blib setup\$(EXE_EXT) /m;

   $inherited; #

}

sub MY::distdir {

   my $inherited = shift->SUPER::distdir(@_);

   $inherited =~ s/^(distdir .*)$/$1 distsignature/m;

   $inherited; #

}

sub MY::pm_to_blib {

   use Config;

   my $inherited = shift->SUPER::pm_to_blib(@_);

   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_host.pm") &&
         ($inherited !~ /Custom\/fa_host.pm/)) {
      my $fa_h="\t  lib\/Net\/FullAuto\/Custom\/fa_host.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/fa_host.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/fa_host.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/fa_host.pm).*/$1 \\\n$fa_h$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/fa_host.pm.*\n//m;
   }
   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") &&
         ($inherited !~ /Custom\/fa_conf.pm/)) {
      my $fa_g="\t  lib\/Net\/FullAuto\/Custom\/fa_conf.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/fa_conf.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/fa_conf.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/fa_conf.pm).*/$1 \\\n$fa_g$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/fa_conf.pm.*\n//m;
   }
   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_menu.pm") &&
         ($inherited !~ /Custom\/fa_menu.pm/)) {
      my $fa_m="\t  lib\/Net\/FullAuto\/Custom\/fa_menu.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/fa_menu.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/fa_menu.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/fa_menu.pm).*/$1 \\\n$fa_m$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/fa_menu.pm.*\n//m;
   }
   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_code.pm") &&
         ($inherited !~ /Custom\/fa_code.pm/)) {
      my $fa_c="\t  lib\/Net\/FullAuto\/Custom\/fa_code.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/fa_code.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/fa_code.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/fa_code.pm).*/$1 \\\n$fa_c$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/fa_code.pm.*\n//m;
   }
   
   $inherited =~ s/\s+\\(\s*[$][(]NOE)/$1/s;
   $inherited =~ s/([\$][(]NOECHO[)] [\$])/-$1/s;
   my $newline_flag=0;
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") {
      $inherited .= "\t\$(SED) \'s/^#[ ]*our[ ]*\\(.\\)editor[ ]*[=].*/".
         'our \\1'."editor = \"$editor\";/g\' ".
         "blib/lib/Net/FullAuto/Custom/fa_conf.pm >tmp_conf.pm\n".
         "\t\$(MV) tmp_conf.pm blib/lib/Net/FullAuto/Custom/fa_conf.pm\n\n"
         if defined $editor and $editor;
   } else {
      $newline_flag=1;
      $inherited .= "\n";
   }

   unless (-e $Config{installsitelib}."/Net/FullAuto/FA_Core.pm") {
      $inherited .= "\t\$(SED) \'s/^[ ]*our[ ]*\\(.\\)".
         "cygwin_berkeley_db_mode[ ]*[=].*/".'our \\1'.
         "cygwin_berkeley_db_mode = $cygwin_berkeley_db_mode;/g\' ".
         "blib/lib/Net/FullAuto/FA_Core.pm >tmp_fa_core.pm\n".
         "\t\$(MV) ./tmp_fa_core.pm blib/lib".
         "/Net/FullAuto/FA_Core.pm\n\n"
         if $^O eq 'cygwin';
   } elsif (!$newline_flag) {
      $inherited .= "\n";
   }

   $inherited; #

}

package FA::LWP::UserAgent;
use strict;
our @ISA = qw(LWP::UserAgent); # inherits from LWP::UserAgent
use vars qw(@ISA $USER $PASSWD $SETUPDONE);
# we delay requiring LWP::UserAgent and setting up inheritance until we need it

$FA::LWP::UserAgent::VERSION = "1.94";

sub config {
    return if $SETUPDONE;
    if ($CPAN::META->has_usable('LWP::UserAgent')) {
        require LWP::UserAgent;
        @ISA = qw(Exporter LWP::UserAgent); ## no critic
        $SETUPDONE++;
    } else {
        $CPAN::Frontend->mywarn("  LWP::UserAgent not available\n");
    }
}

sub get_basic_credentials {
    my($self, $realm, $uri, $proxy) = @_;
    if ($USER && $PASSWD) {
        return ($USER, $PASSWD);
    }
    if ( $proxy ) {
        ($USER,$PASSWD) = $self->get_proxy_credentials();
    } else {
        ($USER,$PASSWD) = $self->get_non_proxy_credentials();
    }
    return($USER,$PASSWD);
}

sub get_proxy_credentials {
    my $self = shift;
    my ($user, $password);
    if ( defined $CPAN::Config->{proxy_user} ) {
        $user = $CPAN::Config->{proxy_user};
        $password = $CPAN::Config->{proxy_pass} || "";
        return ($user, $password);
    }
    my $username_prompt = "\nProxy authentication needed!
 (Note: to permanently configure username and password run
   o conf proxy_user your_username
   o conf proxy_pass your_password
     )\nUsername:";
    ($user, $password) =
        _get_username_and_password_from_user($username_prompt);
    return ($user,$password);
}

sub get_non_proxy_credentials {
    my $self = shift;
    my ($user,$password);
    if ( defined $CPAN::Config->{username} ) {
        $user = $CPAN::Config->{username};
        $password = $CPAN::Config->{password} || "";
        return ($user, $password);
    }
    my $username_prompt = "\nAuthentication needed!
     (Note: to permanently configure username and password run
       o conf username your_username
       o conf password your_password
     )\nUsername:";

    ($user, $password) =
        _get_username_and_password_from_user($username_prompt);
    return ($user,$password);
}

sub _get_username_and_password_from_user {
    my $username_message = shift;
    my ($username,$password);

    ExtUtils::MakeMaker->import(qw(prompt));
    $username = prompt($username_message);
        if ($CPAN::META->has_inst("Term::ReadKey")) {
            Term::ReadKey::ReadMode("noecho");
        }
    else {
        $CPAN::Frontend->mywarn(
            "Warning: Term::ReadKey seems not to be available, ".
            "your password will be echoed to the terminal!\n"
        );
    }
    $password = prompt("Password:");

        if ($CPAN::META->has_inst("Term::ReadKey")) {
            Term::ReadKey::ReadMode("restore");
        }
        $CPAN::Frontend->myprint("\n\n");
    return ($username,$password);
}

# mirror(): Its purpose is to deal with proxy authentication. When we
# call SUPER::mirror, we relly call the mirror method in
# LWP::UserAgent. LWP::UserAgent will then call
# $self->get_basic_credentials or some equivalent and this will be
# $self->dispatched to our own get_basic_credentials method.

# Our own get_basic_credentials sets $USER and $PASSWD, two globals.

# 407 stands for HTTP_PROXY_AUTHENTICATION_REQUIRED. Which means
# although we have gone through our get_basic_credentials, the proxy
# server refuses to connect. This could be a case where the username or
# password has changed in the meantime, so I'm trying once again without
# $USER and $PASSWD to give the get_basic_credentials routine another
# chance to set $USER and $PASSWD.

# mirror(): Its purpose is to deal with proxy authentication. When we
# call SUPER::mirror, we relly call the mirror method in
# LWP::UserAgent. LWP::UserAgent will then call
# $self->get_basic_credentials or some equivalent and this will be
# $self->dispatched to our own get_basic_credentials method.

# Our own get_basic_credentials sets $USER and $PASSWD, two globals.

# 407 stands for HTTP_PROXY_AUTHENTICATION_REQUIRED. Which means
# although we have gone through our get_basic_credentials, the proxy
# server refuses to connect. This could be a case where the username or
# password has changed in the meantime, so I'm trying once again without
# $USER and $PASSWD to give the get_basic_credentials routine another
# chance to set $USER and $PASSWD.

sub mirror {
    my($self,$url,$aslocal) = @_;
    my $result = $self->SUPER::mirror($url,$aslocal);
    if ($result->code == 407) {
        undef $USER;
        undef $PASSWD;
        $result = $self->SUPER::mirror($url,$aslocal);
    }
    $result;
}

package ExtUtils::MM_Unix; # Needed to disable sigdie
                           # when checking for ARG_MAX

sub max_exec_len {
    my $self = shift;

    if (!defined $self->{_MAX_EXEC_LEN}) {
        if (my $arg_max = eval {
               local $SIG{__DIE__}; # No sigdie handler 
               require POSIX;  &POSIX::ARG_MAX }) {
            $self->{_MAX_EXEC_LEN} = $arg_max;
        }
        else {      # POSIX minimum exec size
            $self->{_MAX_EXEC_LEN} = 4096;
        }
    }

    return $self->{_MAX_EXEC_LEN};
}

package OS2;

sub DLLname {}

package ExtUtils::MM_Any;

sub xs_dlsyms_ext {}

1;
