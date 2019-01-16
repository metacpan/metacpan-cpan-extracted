#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;
use Module::ScanDeps qw/scan_line/;

{
my $chunk=<<'EOT';
use strict;
EOT
my @array=scan_line($chunk);@array=sort @array;
is_deeply(\@array,[sort qw{strict.pm}]);
}

{
my $chunk=<<'EOT';
require 5.10;
EOT
my @array=scan_line($chunk);@array=sort @array;
is_deeply(\@array,[sort qw{feature.pm}]);
}

{# RT#48151
my $chunk=<<'EOT';
require __PACKAGE__ . "SomeExt.pm";
EOT
eval {
  scan_line($chunk);
};
is($@,'');
}

{  #  use 5.010 in one-liners was only returning feature.pm (actually, 5.9.5 or higher)
  my $chunk = 'use 5.010; use MyModule::PlaceHolder1;';
  my @got = scan_line($chunk);
  #diag @got;
  my @expected = sort ('feature.pm', 'MyModule/PlaceHolder1.pm');
  is_deeply (\@expected, [sort @got], 'got more than just feature.pm when "use 5.010" in one-liner');
}

{  #  use 5.009 in one-liners should not return feature.pm
  my $chunk = 'use 5.009; use MyModule::PlaceHolder1;';
  my @got = scan_line($chunk);
  #diag @got;
  my @expected = sort ('MyModule/PlaceHolder1.pm');
  is_deeply (\@expected, [sort @got], 'did not get feature.pm when "use 5.009" in one-liner');
}


{  #  avoid early return when pragma is found in one-liners
  my $chunk = 'use if 1, MyModule::PlaceHolder2; use MyModule::PlaceHolder1;';
  my @got = scan_line($chunk);
  #diag @got;
  my @expected = sort ('if.pm', 'MyModule/PlaceHolder1.pm', 'MyModule/PlaceHolder2.pm');
  is_deeply (\@expected, [sort @got], 'if-pragma used in one-liner');
}

{  #  avoid early return when pragma is found in one-liners
  my $chunk = 'use autouse "MyModule::PlaceHolder2"; use MyModule::PlaceHolder1;';
  my @got = scan_line($chunk);
  #diag @got;
  my @expected = sort ('autouse.pm', 'MyModule/PlaceHolder1.pm', 'MyModule/PlaceHolder2.pm');
  is_deeply (\@expected, [sort @got], 'autouse pragma used in one-liner');
}



{
  my $chunk= "{ package foo; use if 1, 'warnings' }";
  my @array=sort(scan_line($chunk));
  is_deeply(\@array,[sort qw{if.pm warnings.pm}]);
}

{
  my $chunk= "{ use if 1, 'warnings' }";
  my @array=sort(scan_line($chunk));
  is_deeply(\@array,[sort qw{if.pm warnings.pm}]);
}

{
  my $chunk= " do { use if 1, 'warnings' }";
  my @array=sort(scan_line($chunk));
  is_deeply(\@array,[sort qw{if.pm warnings.pm}]);
}

{
  my $chunk= " do { use foo }";
  my @array=sort(scan_line($chunk));
  is_deeply(\@array,[sort qw{foo.pm}]);
}
