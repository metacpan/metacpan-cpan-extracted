#!/usr/bin/env perl
use strict;
use warnings;

my $parentDir = '/home/mojo/perl/Netstack/lib';
my $partInfo  = '.+\.pm$|.+\.pl$|.+\.t$';   #正则表达

&search_file( $parentDir, $partInfo );

sub search_file {
  my ( $dir, $partInfo ) = @_;

  #print $partInfo, "\n";
  opendir my $dh, $dir or die "Cannot open dir $dir\n";
  my @files = readdir $dh; #标量上下文和列表上下文
  foreach my $file (@files) {
    my $filePath = "$dir/$file";
    if (
      ( $file =~ /$partInfo/i )
      #-f 判断是否是文件
      and ( -f $filePath )
      )
    {
      print "$filePath\n";
      system "perltidy -pbp -l 120 -nst -i=2 -ci=2 -bt=2 -cab=0 -b -bext='/'  $filePath";
    }
    if (  ( -d $filePath )
      and ( $file ne '.' )
      and ( $file !~ '.vs' )
      and ( $file ne '..' ) ) #-d判断是否是目录
    {
      &search_file( $filePath, $partInfo );
    }
  }
}
