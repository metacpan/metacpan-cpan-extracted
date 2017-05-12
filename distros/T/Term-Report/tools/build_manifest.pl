#!/usr/bin/perl

  use File::Find;
  use Cwd;

  (my $dir = cwd) =~ s/tools$//;
  open FILE, ">$dir/MANIFEST";

  chdir '../';
  my $topdir = cwd;

  find ({ follow=>1, wanted => sub { 
                        s/^.*\///;
                        $File::Find::dir =~ s/$topdir\/?//;
                        print FILE ($File::Find::dir ? $File::Find::dir."/$_" : $_)."\n" if !/^(\.|CVS|Root|Repository|Entries)/ && !-d; 
                    }
        }, $dir);

