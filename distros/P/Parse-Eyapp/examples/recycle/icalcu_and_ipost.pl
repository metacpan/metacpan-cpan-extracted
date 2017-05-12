#!/usr/bin/perl -w
package CalcActions;
use strict;
use base qw{NoacInh};

sub NUM {
  return $_[1];
}

sub PLUS {
  $_[1]+$_[3];
}

sub TIMES {
  $_[1]*$_[3];
}

package PostActions;
use strict;
use base qw{NoacInh};

sub NUM {
  return $_[1];
}

sub PLUS {
  "$_[1] $_[3] +";
}

sub TIMES {
  "$_[1] $_[3] *";
}

package main;
use strict;

my $calcparser = CalcActions->new();
my $x = "@ARGV";
my $e = $calcparser->Run(0, $x);

unless ($calcparser->YYNberr) {
  print "$e\n";

  my $postparser = PostActions->new();
  my $p = $postparser->Run(0, $x);

  print "$p\n";
}
