#!/usr/bin/perl
#
# Author: T. Zoerner
#
# Testing RPC support
#
# This program is in the public domain and can be used and
# redistributed without restrictions.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

use blib;
use warnings;
use strict;
use Quota;

# ----------------------------------------------------------------------------
##
## insert your test case constants here:
##
my $my_uid = $>;
(my $my_gid = $)) =~ s/ .*//;

my $path         = "/mnt";
my $remote_path  = "/data/tmp/qtest";
my $remote_host  = "localhost";
my $unused_port  = 29875;  # for RPC error testing
my $unknown_host = "UNKNOWN_HOSTNAME";  # for RPC error testing
my $dogrp        = 0;
my $ugid         = ($dogrp ? $my_gid : $my_uid);
my $other_ugid   = ($dogrp ? 2001 : 32000);  # for permission test when not run by admin

my $n_uid_gid= ($dogrp ? "GID" : "UID");  # for use in print output

# ----------------------------------------------------------------------------

sub print_quota_result
{
  my ($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = @_;

  if (defined $bc) {
    if ($bt) {
      my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
      $bt = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $bt;
    }
    if ($ft) {
      my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
      $ft = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $ft;
    }

    print "Query results: $bc ($bs,$bh,$bt) $fc ($fs,$fh,$ft)\n";
  }
  else {
    print "Query failed: ". Quota::strerr() ."\n";
  }
}

# ----------------------------------------------------------------------------

print ">>> stage 1: test locally mounted NFS fs: $path\n";
my $dev = Quota::getqcarg($path);
die "Failed to get device for path $path\n" unless $dev;
print "Using device/argument \"$dev\"\n";

print "Query quotas for $n_uid_gid $ugid...\n";
my @qtup = Quota::query($dev, $ugid, $dogrp);
print_quota_result(@qtup);

if (@qtup) {
  print ">>> stage 1b: Repeat with TCP\n";
  Quota::rpcpeer(0, 1);
  my @qtup2 = Quota::query($dev, $ugid, $dogrp);
  print_quota_result(@qtup2);
  if (!@qtup || (@qtup ne @qtup2)) {
    print("ERROR - results not equal\n");
  }
  Quota::rpcpeer(0, 0);

  print ">>> stage 1c: Repeat with explicit authentication\n";
  Quota::rpcauth($my_uid, $my_gid, "localhost");
  @qtup2 = Quota::query($dev, $ugid, $dogrp);
  print_quota_result(@qtup2);
  if (!@qtup || (@qtup ne @qtup2)) {
    print("ERROR - results not equal\n");
  }
  Quota::rpcauth();
}

# -------------------------------------------------------------------------

print ">>> state 2: repeat with different $n_uid_gid $other_ugid...\n";
@qtup = Quota::query($dev, $other_ugid, $dogrp);
print_quota_result(@qtup);

print ">>> stage 2b: Same with fake authentication\n";
Quota::rpcauth(($dogrp ? $my_uid : $other_ugid),
               ($dogrp ? $other_ugid : $my_gid),
               "localhost");
@qtup = Quota::query($dev, $other_ugid, $dogrp);
print_quota_result(@qtup);
Quota::rpcauth();

# -------------------------------------------------------------------------

print ">>> stage 3: force use of RPC to $remote_host:$remote_path\n";
print "Query quotas for $n_uid_gid $ugid\n";
@qtup = Quota::rpcquery($remote_host, $remote_path, $ugid, $dogrp);
print_quota_result(@qtup);

# -------------------------------------------------------------------------

print ">>> stage 4: force use of inactive remote port...\n";
Quota::rpcpeer($unused_port, 1, 2000);
@qtup = Quota::rpcquery($remote_host, $remote_path, $ugid, $dogrp);
if (!@qtup) {
  print "[Failure is expexted] "; # no newline
}
print_quota_result(@qtup);
Quota::rpcpeer();

print ">>> stage 4b: force use of non-existing remote host...\n";
@qtup = Quota::rpcquery($unknown_host, $remote_path, $ugid, $dogrp);
if (!@qtup) {
  print "[Failure is expexted] "; # no newline
}
print_quota_result(@qtup);
