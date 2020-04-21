#!../../../perl
# ------------------------------------------------------------------------ #
# Interactive test and smoke test for the Perl Quota extension module
#
# This script contains a number of tests that allow exercising most of
# the functionality provided by the Quota module. However these are not
# unit-tests per-se, because firstly, the module functionality depends
# entirely on the environment (i.e. which file-systems are present, is
# quota even enabled on any of these, which users/groups do have quota
# limits set etc.) - so we cannot determine automatically which results
# are correct; secondly, a large portion of the interface can only be
# used in a meaningful way when run by a user with admin capabilities.
#
# Therefore the main test is interactive, which means it will ask you
# for parameters and require you checking results manually. When
# environment variable AUTOMATED_TESTING is set this script will run
# a short smoke test, trying quota operations on all mounted file
# systems; however results cannot be verified, so basically the only
# way to fail that test is a crash in the C code.
#
# Author: T. Zoerner 1995-2020
#
# This program is in the public domain and can be used and redistributed
# without restrictions.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# ------------------------------------------------------------------------ #

use blib;
use warnings;
use strict;
use Quota;

my $my_uid = $>;
(my $my_gid = $)) =~ s/ .*//;  # $) may be a list of GIDs

# ----------------------------------------------------------------------------

if ($ENV{AUTOMATED_TESTING}) {
  smoke_test();
  exit(0);
}
if (! -t STDIN || ! -t STDOUT) {
  print STDERR "\nThis is an interactive test script - input and output must be a tty\nExiting now.\n";
  exit;
}

# ----------------------------------------------------------------------------
#
# Helper function for printing quota query result
#
sub print_quota_result
{
  my ($desc, $bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = @_;

  if (defined $bc) {
    if ($bt) {
      my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
      $bt = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $bt;
    }
    if ($ft) {
      my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
      $ft = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $ft;
    }

    print "$desc $bc ($bs,$bh,$bt) $fc ($fs,$fh,$ft)\n";
  }
  else {
    print "Query failed: ". Quota::strerr() ."\n";
  }
}

# ----------------------------------------------------------------------------
# Smoke-test for automated testing:
# - iterate across mount table
# - for each entry try to get quota device parameter
# - when available, try sync and query UID twice, GID once
# - note setqlim is omitted intentionally (usually will fail as no sane
#   automation would run as root, but if so quotas would be corrupted)
# - test may fail only upon crash or mismatch in repeated UID query;
#   cannot verify failures or query results otherwise
# - tester should manually compare output with that of "quota -v"

sub smoke_test
{
  print "OS: ". `uname -rs` ."\n";
  print "Quota arg type: ". Quota::getqcargtype() ."\n\n";

  print "------------------------------------------------------------------\n".
        "Output of quota -v:\n".
        `quota -v`.
        "------------------------------------------------------------------\n".
        "Output of quota -v -g $my_gid:\n".
        `quota -v -g $my_gid`.
        "------------------------------------------------------------------\n";

  my @Mtab;
  if(!Quota::setmntent()) {
    while(my @ent = Quota::getmntent())
    {
      push @Mtab, \@ent;
    }
  }
  Quota::endmntent();

  foreach my $ent (@Mtab)
  {
    my ($fsname,$path,$fstyp,$fsopt) = @$ent;

    print "$path:\n- fsname/typ: $fsname, $fstyp\n- options: $fsopt\n";

    my $dev = Quota::getdev($path);
    $dev = "UNDEF" unless defined $dev;
    print "- Quota::getdev: $dev\n";

    my $qcarg = Quota::getqcarg($path);
    if ($qcarg) {
      print "- Quota::getqcarg: $qcarg\n";

      if (Quota::sync($qcarg) == 0) {
        print "- Quota::sync: OK\n";
      } else {
        print "- Quota::sync failed: ". Quota::strerr() ."\n";
      }

      my @qtup = Quota::query($qcarg);
      if (@qtup) {
        print "- Quota::query default (EUID): ".join(", ", @qtup)."\n";

        my @qtup2 = Quota::query($qcarg, $my_uid, 0);
        if (@qtup2) {
          print "- Quota::query UID $my_uid: ".join(", ", @qtup2)."\n";
          die "ERROR: mismatching query results\n" if "@qtup" ne "@qtup2";
        } else {
          print "- Quota::query UID $my_uid failed: ". Quota::strerr() ."\n";
          die "ERROR: repeated query failed\n";
        }
      } else {
        print "- Quota::query UID failed: ". Quota::strerr() ."\n";
      }

      @qtup = Quota::query($qcarg, $my_gid, 1);
      if (@qtup) {
        print "- Quota::query GID $my_gid: ".join(", ", @qtup)."\n";
      } else {
        print "- Quota::query GID $my_gid failed: ". Quota::strerr() ."\n";
      }
    } else {
      print "- Quota::getqcarg: UNDEF\n";
    }
    print "\n";
  }
}

# ----------------------------------------------------------------------------
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
my $n_uid_gid= ($quota_kind ? "GID" : "UID");  # for use in print output


# ----------------------------------------------------------------------------
##
##  Query "path" parameter and derive (pseudo) device
##
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

# ----------------------------------------------------------------------------
##
##  Query with one argument (uid defaults to getuid(), "kind" to 0 = user)
##

my $uid_val = ($quota_kind ? $my_gid : $my_uid);
print "\nQuerying this fs with default (which is real $n_uid_gid) $uid_val\n";
my @qtup = ($quota_kind ? Quota::query($dev,$uid_val,$quota_kind)
                        : Quota::query($dev));
print_quota_result("Your usage and limits are: ", @qtup);

##
##  Query with two arguments
##

{
  print "\nEnter a different $n_uid_gid to query quota for: ";
  chomp($uid_val = <STDIN>);
  unless($uid_val =~ /^\d+$/) {
    print "You have to enter a decimal 32-bit value here.\n";
    redo;
  }
}
print "Querying this fs for $n_uid_gid $uid_val\n";
@qtup = Quota::query($dev, $uid_val, $quota_kind);
print_quota_result("Usage and limits for $n_uid_gid $uid_val are:", @qtup);

# ----------------------------------------------------------------------------
##
##  Query quotas via forced RPC
##
my $remhost = 'localhost';
if ($dev =~ m#^([^:]+):(/.*)$#) {
    # path is already mounted via NFS: get server-side mount point to avoid recursion
    $remhost = $1;
    $path = $2;
}
print "\nEnter host:path for querying via forced RPC (default $remhost:$path)\n";
while (1) {
    print "Enter host:path, empty for default, or \":\" to skip: ";
    chomp(my $hap = <STDIN>);
    last unless $hap;  # use default
    if (($hap eq ":") || ($hap eq ".")) {  # skip
        $remhost = "";
        last;
    }
    if ($hap =~ m#^([^:]+):(/.*)$#) {
        $remhost = $1;
        $path = $2;
        last;
    }
    print "Invalid input: not in format \"host:/path\"\n";
}
if ($remhost) {
  @qtup = ($quota_kind ? Quota::rpcquery($remhost, $path, $my_uid, $quota_kind)
                       : Quota::rpcquery($remhost, $path));
  print_quota_result("Your usage and limits are:", @qtup);

  print "Querying $n_uid_gid $uid_val from $remhost:$path via RPC\n";
  @qtup = Quota::rpcquery($remhost, $path, $uid_val, $quota_kind);
  if(!@qtup) {
    warn "Failed RPC query: ".Quota::strerr()."\n\n";
    print "Retrying with fake authentication for $n_uid_gid $uid_val.\n";
    if ($quota_kind == 1) {
      Quota::rpcauth(-1, $uid_val);  # GID
    }
    else {
      Quota::rpcauth($uid_val);
    }
    @qtup = Quota::rpcquery($remhost, $path, $uid_val, $quota_kind);
  }
  print_quota_result("Usage and limits for $n_uid_gid $uid_val are:", @qtup);

  Quota::rpcauth();  # reset to default (must be after strerr output)
}

# ----------------------------------------------------------------------------
##
##  Set quota limits for a local path
##

while(1) {
  print "\nEnter path to set quota (empty to skip): ";
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

      print "Reading back modified limits\n";
      my ($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = Quota::query($dev, $uid_val, $quota_kind);
      if(defined($bc)) {
        if (($bs == $lim[0]) && ($bh == $lim[1]) &&
            ($fs == $lim[2]) && ($fh == $lim[3])) {
          print "OK: results match\n";
        }
        else {
          print "ERROR: results do not match: $bs, $bh, $fs, $fh\n";
        }
      }
      else {
        warn "Failed to read back changed quota limits:".Quota::strerr()."\n";
      }
    }
    else {
      warn "Failed to set quota: ".Quota::strerr()."\n";
    }
  }
}

# ----------------------------------------------------------------------------
##
##  Force immediate update on disk
##

if($dev && ($dev !~ m#^[^/]+:#)) {
  Quota::sync($dev) && ($! != 1) && die "Quota::sync: ".Quota::strerr()."\n";
}
