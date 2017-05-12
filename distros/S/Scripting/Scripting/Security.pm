# File:     $Source: /Users/clajac/cvsroot//Scripting/Scripting/Security.pm,v $
# Author:   $Author: clajac $
# Date:     $Date: 2003/07/21 10:10:05 $
# Revision: $Revision: 1.3 $

package Scripting::Security;

use DB_File;
use strict;

my %Signed;
my $use_signing = 0;

my $current;

sub open {
  my ($pkg, $file) = @_;
 
  warn "Signature database not found\n" unless(-e $file && -f $file);
  if(tie(%Signed, 'DB_File', $file, O_RDONLY, 0666, $DB_HASH)) {
    $use_signing = 1;
  } else {
    warn "Failed to open signature database\n";
  }

  1;
}

sub executing {
  my ($pkg, $path) = @_;

  $current = $path;
}

sub match {
  my ($pkg, $path, $digest) = @_;
  return 1 unless($use_signing);
  return 0 unless(exists $Signed{$path});
  return 0 unless($Signed{$path} eq $digest);
  return 1;
}

sub secure {
  return 1 unless($use_signing);
  if(exists $Signed{$current}) {
    return 1;
  }
}

1;
