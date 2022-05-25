package fa_code_demo;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2022  Brian M. Kelly
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

use strict;
use warnings;
our $test=0;our $timeout=0;
require Exporter;
#use threads ();
#use Thread::Queue;
our @ISA = qw(Exporter Net::FullAuto::FA_Core);
use Net::FullAuto::FA_Core;

#################################################################
##  Do NOT alter code ABOVE this block.
#################################################################

##  -------------------------------------------------------------
##  SET CONFIGURATION PARAMETERS HERE:
##  -------------------------------------------------------------

#####  SET EMAIL AUTOMATION SETTINGS  ########
my $email_to=[
               ']USERNAME[',
               'Brian.Kelly@fullauto.com',
             ];
#%email_defaults=(
#   Usage       => 'notify_on_error',
#   Mail_Method => 'smtp',
#   Mail_Server => 'mailserver.fullauto.com',
#   Reply_To    => 'Brian.Kelly@fullauto.com',
#   To          => $email_to,
#   From        => "$progname\@fullauto.com"
#);
##############################################

##  -------------------------------------------------------------
##  WRITE "RESULT" SUBROUTINES HERE:
##  -------------------------------------------------------------

sub hello_world {

   print "\n   Net::FullAuto says \"HELLO WORLD!\"\n";

}

sub hello_world_old {

    #print "\nFIRST PARAMETER=$_[0]\n";
    #print "SECOND PARAMETER=$_[1]\n";
    my $localhost=connect_shell();
    my $hostname=$localhost->cmd('hostname');
    my $stdout='';
    my $stderr='';
    my $computer_zero='';
    my $computer_one='';
    ($computer_zero,$stderr)=connect_host('Zero'); # Connect to
                                        # Remote Host via ssh
    if ($stderr) {
       print "We Have an ERROR when attempting to connect to Zero! : $stderr\n";
    }

    if ($hostname eq 'bkelly-laptop') {
       $computer_one=connect_ssh('VB_Ubuntu'); # Connect to
                                            # Remote Host via ssh
    } else {
       $computer_one=connect_host('Ubuntu'); # Connect to
                                            # Remote Host via ssh
    }
    print "\nHELLO=",$localhost->cmd('echo "hello world"'),"\n";
    print "HOSTNAME=$hostname\n";
    print "HELLO WORLD\n";
    ($stdout,$stderr)=$computer_one->cmd('hostname');
    print "Ubuntu=$stdout\n";
    ($stdout,$stderr)=$computer_zero->cmd('hostname');
    print "Zero=$stdout\n\n";
    ($stdout,$stderr)=$computer_zero->cwd('/develop/deployment/dest');
    print "STDERR=$stderr<==\n" if $stderr;
    my $file='';
    ($file,$stderr)=$computer_zero->cmd('ls ID*');
    print "Zero File=$file<==\n\n";
    return unless $file;
    ($stdout,$stderr)=$computer_zero->get($file); # Get the File
    if ($stderr) {                                # Check Results
       print "We Have an ERROR! : $stderr\n";
    }
    ($stdout,$stderr)=$computer_one->cwd('/home/qa/import');
    print "STDERR=$stderr\n" if $stderr;
    ($stdout,$stderr)=$computer_one->put($file); # Get the File
    if ($stderr) {                               # Check Results
       print "We Have an ERROR! : $stderr\n";
    }
    ($stdout,$stderr)=$computer_one->cmd('ls');
    print $computer_one->{_hostlabel}->[0]," ls output:\n\n$stdout\n";
    ($stdout,$stderr)=$computer_one->cmd('pwd');
    print "CURDIR=$stdout\n\n" if $stdout;

}

sub figlet_fonts {

   Net::FullAuto::FA_Core::figlet();

}

sub menu_demo {

   my @list=`ls -1 /bin`;
   my %Menu_1=(

      Item_1 => {

         Text    => "/bin Utility - ]Convey[",
         Convey  => [ `ls -1 /bin` ],

      },

      Select => 'Many',
      Banner => "\n   Choose a /bin Utility :\n\n"
   );

   my $unattended=0;
   my @selections=&Menu(\%Menu_1,$unattended);
   print "\nSELECTIONS = @selections\n";

}

sub howdy_world {
   open (FH,">FullAuto_howdy_world.txt");
   FH->autoflush(1);
   my $cnt=0;
   while (1) {
      print FH $cnt++;
#      sleep 2;
      last if $cnt==20;
   }
   #----------------------------------------------
   # Connect to Remote Host with *BOTH* ssh & sftp
   #----------------------------------------------
   my ($host,$stderr)=('','');
   my $hostname=`hostname`;
   chomp $hostname;
   my $hostlab='Laptop';
   if ($hostname eq 'opensolaris') {
      ($host,$stderr)=connect_secure('Laptop');
   } elsif ($hostname eq 'reedfish-laptop') {
      ($host,$stderr)=connect_secure('Laptop');
   } else {
      $hostlab='Solaris';
      ($host,$stderr)=connect_secure('Solaris');
   }
   if ($stderr) {
      print "       We Have an ERROR when attempting to connect ",
            "to Ubuntu! :\n$stderr       in fa_code.pm ",
            "Line ",__LINE__,"\n";
      my %mail=(
         'To'      => [ 'Brian.Kelly@bcbsa.com' ],
         'From'    => 'Brian.Kelly@fullauto.com',
         'Body'    => "\nFullAuto ERROR =>\n\n".$stderr.
                      "       in fa_code.pm Line ".__LINE__,
         'Subject' => "FullAuto ERROR Encountered When Connecting to Ubuntu",
      );
      my $ignore='';my $emerr='';
      ($ignore,$emerr)=&send_email(\%mail);
      if ($emerr) {
         die "\n\n       $stderr\n       EMAIL ERROR =>$emerr<==\n\n";
      } else {
         #die $stderr;
         return;
      }
   }
   print "LOGIN SUCCESSFUL\n";
   print FH "LOGIN SUCCESSFUL ",`date`,"\n";
   close FH;
   &cleanup();
}

sub compare_fa_code {

   my ($solaris_ssh,$solaris_sftp,$laptop_sftp,$output,$stderr)=
      ('','','','','');
   my $localhost=connect_shell();
   ($solaris_ssh,$stderr)=connect_ssh('Solaris');
   ($solaris_sftp,$stderr)=connect_sftp('Solaris');
   print "SFTP_CONNECT_STDERR=$stderr\n" if $stderr;
   my $fa_code_p='/usr/local/lib/perl5/site_perl/5.12.1'.
            '/Net/FullAuto/Custom/opens/Code/fa_code.pm';
   ($output,$stderr)=$solaris_ssh->cmd("cp $fa_code_p /export/home/opens");
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$solaris_ssh->cmd(
      "chown opens /export/home/opens/fa_code.pm");
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$solaris_sftp->lcd($ENV{HOME});
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$solaris_sftp->get('fa_code.pm');
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$solaris_ssh->cmd("rm /export/home/opens/fa_code.pm");
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$localhost->cmd(
      "mv /home/ubuntu/fa_code.pm /home/ubuntu/fa_code.prod");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($laptop_sftp,$stderr)=connect_sftp('Laptop');
   die $stderr if $stderr;
   ($output,$stderr)=$laptop_sftp->lcd($ENV{HOME});
   print "STDERR=$stderr\n" if $stderr;
   my $fa_code_d='/usr/lib/perl5/site_perl/5.10'.
            '/Net/FullAuto/Custom/KB06606/Code/fa_code.pm';
   ($output,$stderr)=$laptop_sftp->get($fa_code_d);
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$localhost->cmd(
      "mv $ENV{HOME}/fa_code.pm $ENV{HOME}/fa_code.dev");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$localhost->cmd(
      "diff $ENV{HOME}/fa_code.dev $ENV{HOME}/fa_code.prod > ".
      "$ENV{HOME}/fa_code_dev_prod.diff");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$localhost->cmd(
      "rm $ENV{HOME}/fa_code.prod $ENV{HOME}/fa_code.dev");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$laptop_sftp->cwd(
      "/cygdrive/c/Documents and Settings/kb06606/Desktop/Compare fa_code.pm");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$laptop_sftp->put(
      "/home/ubuntu/fa_code_dev_prod.diff");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$localhost->cmd(
       "rm $ENV{HOME}/fa_code_dev_prod.diff");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
}

sub remote_hostname {

    my ($computer_one,$stdout,$stderr);      # Scope Variables

    $computer_one=connect_ssh('REMOTE COMPUTER ONE'); # Connect to
                                             # Remote Host via ssh

    ($stdout,$stderr)=$computer_one->cmd('hostname');

    print "REMOTE ONE HOSTNAME=$stdout\n";

}

sub get_file_from_one {

   my ($computer_one,$stdout,$stderr);         # Scope Variables
   my $localhost=connect_shell();

   $computer_one=connect_reverse('REMOTE COMPUTER ONE'); # Connect
                                               # to Remote Host via
                                               # ssh *and* sftp

   ($stdout,$stderr)=$computer_one->cmd(
                     'echo test > test.txt');  # Run Remote Command

   ($stdout,$stderr)=$computer_one->cmd(
                     'zip /tmp/test test.txt');     # Run Remote Command

   if ($stderr) {                              # Check Results
      print "We Have an ERROR! : $stderr\n";
   } else {
      print "Output of zip command from Computer One:".
            "\n\n$stdout\n\n";
   }

   ($stdout,$stderr)=$computer_one->get(
                     '/tmp/test.zip');              # Get the File

   if ($stderr) {                              # Check Results
      print "We Have an ERROR! : $stderr\n";
   } else {
      print "Output of zip command from Computer One:".
            "\n\n$stdout\n\n";
   }

   ($stdout,$stderr)=$localhost->cmd(
                     'unzip test.zip');        # Run Local Command

   if ($stderr) {                              # Check Results
      print "We Have an ERROR! : $stderr\n";
   } else {
      print "Output of unzip command from Computer One:".
            "\n\n$stdout\n\n";
   }

}

########### END OF SUBS ########################

#################################################################
##  Do NOT alter code BELOW this block.
#################################################################

## Important! The '1' at the Bottom is NEEDED!
1
