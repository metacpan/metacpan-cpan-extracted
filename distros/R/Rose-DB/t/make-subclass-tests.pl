#!/usr/bin/perl

use strict;

use FindBin qw($Bin);

chdir($Bin) or die "chdir($Bin) - $!";

opendir(my $dir, '.') or die "Could not opendir(.) - $!";

while(my $file = readdir($dir))
{
  next  if($file !~ /\.t$/ || $file =~ /fork-|subclass|warning|pod|storable|pk-columns|no-registry|setup|db_cache/);

  my $new_file = "subclass-$file";

  open(my $old, $file) or die "Could not open $file - $!";
  open(my $new, ">$new_file") or die "Could not create $new_file - $!";

  while(<$old>)
  {
    # I know, I know...
    unless(/^\s*use_ok|Rose::DB::(\w+)|->isa\(/)
    {
      s/\bRose::DB([^:A-Za-z0-9_])/My::DB2$1/g;
    }

    print $new $_;
  }

  close($old);
  close($new) or die "Could not write $new - $!";
}

closedir($dir);
