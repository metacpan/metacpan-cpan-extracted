#!/usr/bin/perl
#
# patch.pl v0.01
#
# fix up calls to malloc, calloc and realloc so that all
# memory regions are tracked and can subsequently be freed.
#
my $free_ignore	= '(?:istream|rbldnsd_util)';

my $dir			= 'rbldnsd/';
my $rbldnsd_c		= 'rbldnsd.c';
my $Makefile_in		= 'Makefile.in';
my $rbldnsd_packet_c	= 'rbldnsd_packet.c';
my $utility		= 'rbldnsd_util.c';
my $mempool_h		= 'mempool.h';

my $patch		= 'patch/';
my $rblf_mem_h		= 'rblf_mem.h';
my $util_patch		= 'rbldnsd_util.c.patch';
my $rbldnsd_add		= 'rbldnsd.c.patch';
my $rbldnsd_packet_add	= 'rbldnsd_packet.c.patch';
my $Makefile_in_add	= 'Makefile.in.patch';

local (*IN,*OUT,*INSERT,*D);

sub make_orig {
  my $file = shift;
  unless (-e $file .'.org') {
    rename $file, $file .'.org';
  }
  return $file .'.org';
}

sub my_cat {
  my($file,$addition) = @_;
  local *F;
  open(F,$file) or
	die "my_cat1: could not open '$file' for read\n";
  undef local $/;
  my $contents = <F>;
  close F;
  open(F,$addition) or
	die "my_cat2: could not open '$addition' for read\n";
  $contents .= <F>;
  close F;
  make_orig($file);
  open(F,'>'. $file .'.tmp') or
	die "my_cat3: could not open '${file}.tmp' for write\n";
  print F $contents;
  close F;
  rename $file .'.tmp', $file;
}

##################### memory patch #########################
############################################################
# insert definition for rblf_mtfree
#
my $file = $dir . $mempool_h;
my $orig = make_orig($file);
(-e $orig && open (IN,$orig)) or
	die "${mempool_h}: could not open '$orig' for read\n";
open (OUT,'>'. $file) or
	die "${mempool_h}: could not open '${file} for write\n";
my $found = 0;
my $waiting = 0;
my $contents;
while (<IN>) {
  print OUT $_;
  if (! $found && $_ =~ /define/) {
    print OUT qq|#include "rblf_mem.h"\n|;
    $found = 1;
  }
}
close IN;
close OUT;

################ free( and main( patch ####################  
############################################################
# replace globally 'free' with 'rblf_mtfree'
# everywhere except in istream.c and rbldns_util.c
#
# replace 'main' with 'mainx'
#
opendir (D,$dir) or
	die "dir: could not open '$dir' for scan\n";
my @file = grep(/\.c$/ && $_ !~ /$free_ignore/o,readdir(D));
closedir D;
{
	undef local $/;
	foreach(@file) {
	  $file = $dir . $_;
	  (-e $file && open(IN,$file)) or
		die "freemain: could not open '$file' for read\n";
	  $contents = <IN>;
	  close IN;
	  my $updated = $contents =~ s/ free\(/ rblf_mtfree\(/g;
	  $updated += $contents =~ s/main\(/mainx\(/;
	  if ($updated) {
	    make_orig($file);
	    open(OUT,'>'. $file) or
		die "freemain: could not open '${file}' for write\n";
	    print OUT $contents;
	    close OUT;
	  }
	}
}

##################### memory patch #########################  
############################################################
# replace malloc, calloc, realloc with tracked memory operations
#
$file = $dir . $utility;
$orig = make_orig($file);
(-e $orig && open(IN,$orig)) or
	die "memory: could not open '$orig' for read\n";
open(OUT,'>'. $file) or
	die "memory: could not open '${file}' for write\n";

$found = 0;
foreach(<IN>) {
  if (!$found) {
    if ($_ =~ /^char \*emalloc\(/) {
	$waiting = $found = 1;
	next;
    }
  }
  elsif ($waiting) {
    if ($_ =~ /^char \*ememdup\(/) {
      $waiting = $_;
      open(INSERT,$patch . $util_patch) or
	die "memory: could not open '${patch}$util_patch' for read\n";
      foreach(<INSERT>) {
	print OUT $_;
      }
      close INSERT;
      print OUT $waiting;
      $waiting = 0;
    }
    next;
  }
  print OUT $_;
}
close IN;
close OUT;

##################### memory patch #########################  
############################################################
# copy header file to build directory
#
$file = $rblf_mem_h .'.in';
(-e $file && open(IN,$file)) or
	die "memory: could not open '${file}.in' for read\n";
{
	undef local $/;
	$contents = <IN>;
}
close IN;
open(OUT,'>'. $dir . $rblf_mem_h) or
	die "memory: could not open '${dir}$rblf_mem_h' for write\n";
print OUT $contents;
close OUT;

#################### build patches #########################
############################################################
#

my_cat($dir . $Makefile_in, $patch . $Makefile_in_add);
my_cat($dir . $rbldnsd_c, $patch . $rbldnsd_add);
my_cat($dir . $rbldnsd_packet_c, $patch . $rbldnsd_packet_add);
