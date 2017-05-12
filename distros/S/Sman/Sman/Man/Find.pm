package Sman::Man::Find; 
#$Id$

use File::Find; 
use strict;
use warnings;

# to be called like "my @files = Sman::Man::Find::FindManFiles()" 
sub FindManFiles {  # get manfiles in MANPATH
    my ($manpath, $matchregex) = @_;
    my @files;
    chomp($manpath ||= $ENV{MANPATH} || `manpath` || '/usr/share/man');

    #$matchregex = 'man/man.*\.' unless defined $matchregex;

    my @dirs =  split(/:/, $manpath);
    for my $dir (@dirs) {
        next unless ($dir && -e $dir && (-d $dir || -l $dir));  # skip non-existent dirs
        File::Find::find( sub { 
          my $n = $File::Find::name;
          push @files, $n 
          if -f $n && $n =~ m!man/man.*\.!
       }, $dir ); 
    }
    return @files;
} 

1;

=head1 NAME

Sman::Man::Find - Find manpage files for indexing by sman-update

=head1 SYNOPSIS

  my @manfiles = Sman::Man::Find::FindManFiles();
    
=head1 DESCRIPTION

Provides a single function, FindManFiles(), which looks for man-like files
along the passed manpath, or the env var MANPATH, or the output of manpath,
whichever is defined first. If none is defined, /usr/share/man is used as the
manpath.

=head1 AUTHOR

Josh Rabinowitz <joshr>

=head1 SEE ALSO

L<sman-update>, L<sman>, L<sman.conf>

=cut
