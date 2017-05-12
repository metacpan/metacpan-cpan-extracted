#!/usr/bin/perl
#
# get_rbldnsd.pl	v1.01	michael@bizsystems.com
#

use strict;
#use diagnostics;
my $includes = '';
my $config = '.sources';
my $redor = '';
my $zlib = '--disable-zlib';		# no zlib by default
my $localrbldnsd = './rbldnsd';
my $rbldnsd = '';

if (-e $config && open(F,$config)) {
  foreach (<F>) {
    if ($_ =~ m|^rbldnsd=([^\r\n]+)|i) {
      $rbldnsd = $1;
    }
    if ($_ =~ m|^zlib=([^\r\n]*)|i) {
      $zlib = $1 || '';
    }
  }
  close F;
}

if ($rbldnsd && -e $rbldnsd && -d $rbldnsd && -r $rbldnsd) {
  $rbldnsd .= '/' unless $rbldnsd =~ m|/$|;
  $redor = prompt("\ndo you want to [re]configure RBLDNSD source paths? [no]: ");
  if ($redor && $redor =~ /^y/i) {
    $rbldnsd = '';
  }
  else {
    $redor = '';
  }
}

unless ($rbldnsd) {
  $zlib = prompt("\ndo you want to include support for compressed files? (zlib must be installed) [no]: ");
  $zlib = ($zlib =~ /^y/i) ? '' : '--disable-zlib';
  $rbldnsd = prompt("\npath to 'rbldnsd' source directory, typically something like:\n\n  /usr/src/rbldnsd-{version}\n\n");
}

unless ($rbldnsd && -e $rbldnsd && -d $rbldnsd) {	# this is a valid directory
  print "location of 'rbldnsd' source is REQUIRED to build this module\n";
  exit;
}

$rbldnsd .= '/' unless $rbldnsd =~ m|/$|;
unless (-e $rbldnsd .'rbldnsd.c') {
  print "could not find '${rbldnsd}rbldnsd.c'\n";
  exit;
}

$redor = 1 unless -e $localrbldnsd && -d $localrbldnsd;

if ($redor) {			# get a fresh copy for rbldnsd
  rm_dircon($localrbldnsd);
  copy_r($localrbldnsd,$rbldnsd);
  chmod 0755, 'rbldnsd/configure';

  open(F,'>'. $config) or die "could not open '$config' for write\n";
    print F qq|do not alter this file, written by Makefile.PL\nrbldnsd=$rbldnsd\nzlib=$zlib\n|;
  close F;
  do 'scripts/patch.pl';
  if ($@) {
    die $@;
  }
}

$zlib;
