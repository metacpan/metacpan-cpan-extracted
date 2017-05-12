#!/usr/bin/perl

  use File::Find;
  use Cwd;

  (my $dir = cwd) =~ s/tools$//;
  open FILE, ">$dir/MANIFEST";

  find ({ wanted => sub { 
                        s/^.*\///; 
                        $File::Find::dir =~ s/$File::Find::topdir\/?//;
                        print FILE ($File::Find::dir ? $File::Find::dir."/$_" : $_)."\n" if !/^(\.|CVS|Root|Repository|Entries)/ && !-d; 
                    }
        }, $dir);

