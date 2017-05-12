#!/usr/bin/perl
# ------------------------------------------------------------------------ #
# Interactive test and demo script for the AFS JFS Quota Class Interface
#
# Author: Tom Zoerner, 2007
#
# This program (test_jfs.pl) is in the public domain and can be used and
# redistributed without restrictions.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# ------------------------------------------------------------------------ #

use blib;
use Quota;

if (! -t) {
   print STDERR "\nThis is an interactive test script - input must be a tty\nExiting now.\n";
   exit;
}

{
  print "\nEnter path to get quota for (JFS2 only; default '.'):\n> ";
  chomp($path = <STDIN>);
  $path = "." unless $path =~ /\S/;

  $dev = Quota::getqcarg($path);
  $dev || warn "$path: mount point not found\n";
  if ($dev =~ m#JFS2#) {
    print "Using device/argument \"$dev\"\n";
  } else {
    warn "$path: is not a JFS2 file system\n";
    print "Continuing anyway...\n\n";
  }
}

#
# Enumerate
#
$class = -1;
@class_list = ();
while(1) {
  $class = Quota::jfs2_getnextq($dev, $class);
  last if !defined $class;
  push @class_list, $class;
}
print "Class enumeration returned ". ($#class_list+1) ." classes\n";


#
# Query all existing classes
#
sub print_limit {
  my($dev,$class) = @_;

  ($bs,$bh,$bt,$fs,$fh,$ft) = Quota::jfs2_getlimit($dev, $class);
  if (defined($bs)) {
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
    $bt = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $bt;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
    $ft = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $ft;

    print "Limits for class $class: $bs,$bh,$bt blocks - $fs,$fh,$ft files\n\n";

  } else {
    warn "Quota::jfs2_getlimit($dev,$class): ",Quota::strerr,"\n\n";
    last;
  }
}
print "\n";

for $class (@class_list) {
  print_limit($dev, $class);
}


#
# Create a new class and work with it
#

print "Specify block and file limits for a new class bs,bh,fs,fh (empty to skip):\n> ";
chomp($in = <STDIN>);
if($in =~ /\S/) {
  ($bs,$bh,$fs,$fh) = (split(/\s*,\s*/, $in));
  $class = Quota::jfs2_newlimit($dev, $bs,$bh,0,$fs,$fh,0);
  if (defined $class)  {
    print "Successfully created class $class\n";

    print "Reading back new limits:\n";
    print_limit($dev, $class);

  } else {
    warn "Creation failed: ". Quota::strerr ."\n";
  }

  if (defined $class)
  {
    print "\nModify block and file limits for class $class: bs,bh,fs,fh (empty to skip):\n> ";
    chomp($in = <STDIN>);
    if($in =~ /\S/) {
      ($bs,$bh,$fs,$fh) = (split(/\s*,\s*/, $in));
      if (Quota::jfs2_putlimit($dev, $class, $bs,$bh,0,$fs,$fh,0) == 0) {
        print "Successfully modified limits for class $class\n";

        print "Reading back new limits:\n";
        print_limit($dev, $class);
      } else {
        warn "Modification failed: ". Quota::strerr ."\n";
      }
    }

    {
      print "\nEnter a user ID to assign this class to: (empty to skip)\n";
      chomp($uid = <STDIN>);
      unless($uid =~ /^(\d+)?$/) {
        print "You have to enter a numerical class id.\n";
        redo;
      }
    }
    if ($uid =~ /^\d+$/) {
      if (Quota::jfs2_uselimit($dev, $class, $uid) == 0) {
        print "Successfully assigned class $class to user $uid\n";
      } else {
        warn "Assignment failed: ". Quota::strerr ."\n";
      }
    }

    print "\nDelete the new class? y/n > ";
    chomp($in = <STDIN>);
    if ($in =~ /y/) {
      if (Quota::jfs2_rmvlimit($dev, $class) != 0) {
        warn "Removal failed: ". Quota::strerr ."\n";
      }
    } else {
      print "not confirmed\n";
    }
  }
}

