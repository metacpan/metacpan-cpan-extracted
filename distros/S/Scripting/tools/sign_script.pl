#!/usr/bin/perl

use DB_File;
use Digest::SHA1 qw(sha1);
use IO::File;
use File::Spec;
use Getopt::Long;
use strict;

my ($help, $purge, $remove) = (0,0,0);
my $sign_db = "";
my $sign_file = "";

GetOptions(
	   help => \$help,
	   purge => \$purge,
	   remove => \$remove,
	   'db=s' =>  \$sign_db,
	   'file=s' => \$sign_file,
	   );

if($help) {
  print <<__HELP__
Usage: sign_script.pl [options]
Options:
  --help       Display help information
  -db          Path to signature database
  -file        Path to script file
  --remove     Remove signed script from database
  --purge      Clean up database (removes non-existent file entries)
__HELP__
}

my %Signed;
if($sign_db) {
  tie %Signed, 'DB_File', $sign_db, O_CREAT | O_RDWR, 0644, $DB_HASH || die "Can't open sign db";

  if($purge) {
    print "Purging '$sign_db'\n";
    my $purged = 0;
    foreach(keys %Signed) {
      unless(-e $_ && -f $_) {
	print "  Removing '$_'\n";
	delete $Signed{$_} unless(-e $_ && -f $_);
	$purged++;
      }
    }
    if($purged) {
      print "  $purged entries removed\n";
    } else {
      print "  No files found to purge\n";      
    }
    print "\n";
  }
  
}

if($sign_file) {
  $sign_file = File::Spec->rel2abs($sign_file);

  if($remove) {
    print "Unsigning '$sign_file'\n";
    delete $Signed{$sign_file};
  } else {
    print "Signing '$sign_file'\n";
    my $file = IO::File->new($sign_file, "r");
    my $source = join("",$file->getlines);
    $file->close;
    
    my $digest = sha1($source);

    $Signed{$sign_file} = $digest;
  }
}
