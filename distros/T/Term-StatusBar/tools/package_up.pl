#!/usr/bin/perl

  my $pkg = 'Term-StatusBar';
  my $ver = "1.18";
  `rm -f ../*.gz; ./build_manifest.pl; ./build_readme.pl`;

  open FILE, "../MANIFEST";
  my $str;

  for (<FILE>){
      chomp;
      $str .= "./$pkg/$_ ";
  }

  `tar -C ../.. -zcf $pkg-$ver.tar.gz $str`;
  `mv $pkg-$ver.tar.gz ../`;
  close FILE;

