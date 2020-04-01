#!../../../perl
# ------------------------------------------------------------------------ #
# Interactive test and demo script for the Perl Quota extension module
#
# Author: T. Zoerner 1995-2020
#
# This program (test.pl) is in the public domain and can be used and
# redistributed without restrictions.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# ------------------------------------------------------------------------ #

use blib;
use warnings;
use strict;
use Quota;

if (! -t STDIN || ! -t STDOUT) {
  print STDERR "\nThis is an interactive test script - input and output must be a tty\nExiting now.\n";
  exit;
}
if ($ENV{AUTOMATED_TESTING}) {
  print STDERR "\nNo tests available for AUTOMATED_TESTING - Exiting now.\n";
  exit;
}

##
##  Query "kind" parameter: user (=0) or group (=1) quota
##
my $quota_kind = 0;
while (1) {
  print "\nQuery user [u] or group [g] quota? (default: user)? ";
  if (<STDIN> =~ /^([ug]?)\s*$/) {
    $quota_kind = 1 if ($1 eq "g");
    last;
  }
  warn "invalid response (not 'u' or 'g'), please try again\n";
}


##
##  Query "path" parameter and derive (pseudo) device
##
my $n_uid_gid= ($quota_kind ? "GID" : "UID");  # for use in print output
my ($dev, $path);

while(1) {
  print "\nEnter path to get quota for (NFS possible; default '.'): ";
  chomp($path = <STDIN>);
  $path = "." unless $path =~ /\S/;

  while(1) {
    $dev = Quota::getqcarg($path);
    if(!$dev) {
      warn "$path: mount point not found\n";
      if(-d $path && $path !~ m#/.$#) {
	#
	# try to append "/." to get past automounter fs
	#
	$path .= "/.";
	warn "Trying $path instead...\n";
	redo;
      }
    }
    last;
  }
  redo if !$dev;
  print "Using device/argument \"$dev\"\n";

  ##
  ##  Check if quotas are present on this filesystem
  ##

  if($dev =~ m#^[^/]+:#) {
    print "Is a remote file system\n";
    last;
  }
  elsif(Quota::sync($dev) && ($! != 1)) {  # ignore EPERM
    warn "Quota::sync: ".Quota::strerr()."\n";
    warn "Choose another file system - quotas not functional on this one\n";
  }
  else {
    print "Quotas are present on this filesystem (sync ok)\n";
    last;
  }
}

##
##  Query with one argument (uid defaults to getuid(), "kind" to 0 = user)
##

my $uid_val = ($quota_kind ? $) : $>);
print "\nQuery this fs with default (which is real $n_uid_gid) $>\n";
my ($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = ($quota_kind
                                          ? Quota::query($dev,$uid_val,$quota_kind)
                                          : Quota::query($dev));
if(defined($bc)) {
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
  $bt = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $bt;
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
  $ft = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $ft;

  print "Your usage and limits are $bc ($bs,$bh,$bt) $fc ($fs,$fh,$ft)\n\n";
}
else {
  warn "Quota::query($dev): ".Quota::strerr()."\n\n";
}

##
##  Query with two arguments
##

{
  print "Enter a $n_uid_gid to get quota for: ";
  chomp($uid_val = <STDIN>);
  unless($uid_val =~ /^\d+$/) {
    print "You have to enter a decimal 32-bit value here.\n";
    redo;
  }
}

($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = Quota::query($dev, $uid_val, $quota_kind);
if(defined($bc)) {
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
  $bt = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $bt;
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
  $ft = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $ft;

  print "Usage and limits for $n_uid_gid $uid_val are $bc ($bs,$bh,$bt) $fc ($fs,$fh,$ft)\n\n";
}
else {
  warn "Quota::query($dev,$uid_val,$quota_kind): ".Quota::strerr()."\n\n";
}

##
##  Query quotas via RPC
##

if($dev =~ m#^/#) {
  print "Query localhost:$path via RPC.\n";

  ($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = ($quota_kind
                                         ? Quota::rpcquery('localhost', $path, $uid_val, $quota_kind)
                                         : Quota::rpcquery('localhost', $path));
  if(defined($bc)) {
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
    $bt = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $bt;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
    $ft = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $ft;

    print "Your usage and limits are $bc ($bs,$bh,$bt) $fc ($fs,$fh,$ft)\n\n";
  }
  else {
    warn Quota::strerr()."\n\n";
  }
  print "Query localhost via RPC for $n_uid_gid $uid_val.\n";

  ($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = Quota::rpcquery('localhost', $path, $uid_val, $quota_kind);
  if(!defined($bc)) {
    warn "Failed RPC query: ".Quota::strerr()."\n\n";
    print "Retrying with fake authentication for $n_uid_gid $uid_val.\n";
    if ($quota_kind == 1) {
      Quota::rpcauth(-1, $uid_val);  # GID
    }
    else {
      Quota::rpcauth($uid_val);
    }
    ($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = Quota::rpcquery('localhost', $path, $uid_val, $quota_kind);
    Quota::rpcauth();  # reset to default
  }

  if(defined($bc)) {
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
    $bt = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $bt;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
    $ft = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $ft;

    print "Usage and limits for $n_uid_gid $uid_val are $bc ($bs,$bh,$bt) $fc ($fs,$fh,$ft)\n\n";
  }
  else {
    warn "Failed RPC query: ".Quota::strerr()."\n\n";
  }

}
else {
  print "Skipping RPC query test - already done above.\n\n";
}

##
##  Set quota limits for a local path
##

while(1) {
  print "Enter path to set quota (empty to skip): ";
  chomp($path = <STDIN>);
  last unless $path;

  $dev = Quota::getqcarg($path);
  warn "Heads-up: Trying to set quota for remote path will fail\n" if $dev && ($dev =~ m#^[^/]+:#);
  last if $dev;
  warn "$path: mount point not found\n";
}

if($path) {
  my @lim;
  while(1) {
    print "Enter new quota limits bs,bh,fs,fh for $n_uid_gid $uid_val (empty to abort): ";
    my $in = <STDIN>;
    last unless $in =~ /\S/;
    @lim = ($in =~ /^\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*$/);
    last if scalar(@lim) == 4;
    warn "Invalid parameters: expect 4 comma-separated numerical values\n";
    @lim=();
  }
  if(@lim) {
    unless(Quota::setqlim($dev, $uid_val, @lim, 1, $quota_kind)) {
      print "Quota set successfully for $n_uid_gid $uid_val\n";
    }
    else {
      warn "Failed to set quota: ".Quota::strerr()."\n";
    }
  }
}

##
##  Force immediate update on disk
##

if($dev && ($dev !~ m#^[^/]+:#)) {
  Quota::sync($dev) && ($! != 1) && die "Quota::sync: ".Quota::strerr()."\n";
}
