#!/usr/bin/perl

  my $pkg = 'Sub-Caller';
  my $ver = "0.60";
  `rm -f ../*.gz; ./build_manifest.pl; ./build_readme.pl`;

  open FILE, "../MANIFEST";
  my $str;

  for (<FILE>){
      chomp;
      $str .= "$pkg/$_ ";
  }

  `tar -C ../.. -zcf $pkg-$ver.tar.gz $str`;
  `mv $pkg-$ver.tar.gz ../`;
  close FILE;

