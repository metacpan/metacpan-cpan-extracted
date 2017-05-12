#!/usr/bin/perl

use warnings;
use strict;

opendir my($dh), "." or die;
my(@keep, @delete, %f);

for my $dirent (readdir $dh) {
  next unless $dirent =~ m{^ perl - ([pm] - [^@]+?) @ ([\d]+) $ }x;
  $f{$1}{$2} = $dirent;
  # warn "considering dirent[$dirent]";
}
for my $k (sort keys %f) {
  my @f = sort {$a <=> $b} keys %{$f{$k}};
  # warn "k[$k]f[@f]";
  for my $k2 (0..$#f) {
    if ( $k2 < $#f ) {
      push @delete, $f{$k}{$f[$k2]}
    } else {
      push @keep, $f{$k}{$f[$k2]};
    }
  }
}
if (@keep) {
  print "keep[@keep]\n";
} else {
  print "Found no perl build directories\n";
}
if (@delete){
  my @ok_to_delete = grep { -M > 0.5 } @delete;
  if (my $let_live = scalar @delete - scalar @ok_to_delete) {
    print "not deleting $let_live young directories\n";
    @delete = @ok_to_delete;
  }
  print "delete[@delete]\n"
} else {
  print "nothing to delete\n";
}

use File::Find;

if (@delete) {
  $| = 1;
  my %seen;
  for my $delete (@delete) {
    find({
          wanted => sub {
            lstat;
            if (-l _) {
              unlink $_;
            } elsif (-d _) {
              rmdir $_;
              my $ffn = $File::Find::name;
              my $cntslash = $File::Find::name =~ tr|/||;
              $ffn =~ s|/.*||;
              print $seen{$ffn}++ ? $cntslash < 2 ? "." : "" : "\nrm $ffn";
            } elsif (-f _) {
              unlink $_;
            }
          },
          bydepth => 1,
         }, $delete);
    rmdir $delete;
  }
}
print "\n";
