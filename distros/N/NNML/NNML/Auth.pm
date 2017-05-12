#!/app/unido-i06/magic/perl
#                              -*- Mode: Perl -*- 
# Auth.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Sep 30 08:49:41 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Fri Oct 25 11:44:44 1996
# Language        : CPerl
# Update Count    : 31
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker:  $
# $Log: Auth.pm,v $
# Revision 1.1  1997/02/10 19:47:12  pfeifer
# Switched to CVS
#
# 

package NNML::Auth;
use NNML::Config qw($Config);
use IO::File;
use strict;

my $NORESTRICTION = -1;
my $PASSWD = '';
my $TIME;
my (%PASSWD, %PERM);

sub _update {
  my $norestriction = $NORESTRICTION; 
  if (-e $Config->passwd) {
    if ($PASSWD ne $Config->passwd
        or (stat($Config->passwd))[9] > $TIME) {
      $PASSWD = $Config->passwd;
      $TIME = (stat($Config->passwd))[9];
      
      my $fh = new IO::File '< ' . $Config->passwd;
      if (defined $fh) {
        local ($_);
        while (<$fh>) {
          chomp;
          my($user, $passwd, @perm) = split;
          $PASSWD{$user} = $passwd;
          my %perm;
          @perm{@perm} = @perm;
          $PERM{$user} = \%perm;
        }
        $NORESTRICTION = 0;
      } else {                  # could not read passwd
        $NORESTRICTION = 1;
      }
    }
  } else {                      # tehere is no passwd
    $NORESTRICTION = 1;
  }
  if ($NORESTRICTION != $norestriction) {
    if ($NORESTRICTION) {
      print "Authorization disabled\n";
    } else {
      print "Authorization enabled\n";
    }
  }
}

sub perm {
  my ($con, $command) = @_;

  _update;
  return 1 if $NORESTRICTION;
  return 1 if $command =~ /HELP|QUIT|AUTHINFO|MODE|SLAVE/i;
  return 0 unless $con->{_user};
  return 0 unless $con->{_passwd};

  unless (check($con->{_user}, $con->{_passwd})) {
    # just paranoid
    return 0;
  }
  if ($command =~ /SHUT|CREATE|DELETE|MOVE/i) {
    return $PERM{$con->{_user}}->{'admin'};
  }
  if ($command =~ /POST|IHAVE/i) {
    return $PERM{$con->{_user}}->{'write'};
  }
  return $PERM{$con->{_user}}->{'read'};
}

sub check {
  my ($user, $passwd) = @_;

  _update;
  return 0 unless exists $PASSWD{$user};
  return 1 if $PASSWD{$user} eq '*';
  my $salt = substr($PASSWD{$user},0,2);
  return (crypt($passwd, $salt) eq $PASSWD{$user});
}

sub add_user {
  my ($user, $passwd, @perm) = @_;
  my @cs = ('a'..'z', 'A'..'Z', '0'..'9','.','/');
  srand(time);

  my $salt = $cs[rand(64)] . $cs[rand(64)];
  my $cpasswd = crypt($passwd, $salt);
  my $fh = new IO::File '>>' . $Config->passwd;
  if (defined $fh) {
    $fh->print("$user $cpasswd @perm\n");
    $fh->close;
  } else {
    print "Could not write '%s': $!\n", $Config->passwd;
    return 0;
  }
  return 1;
}


1;
