#!/usr/bin/perl -w
package CalcActions;
use strict;
use base qw{NoacYYDelegateaction};

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
use base qw{CalcActions};

# Since we inherit from CalcActions
# NUM isn't overwritten

sub PLUS {
  "$_[1] $_[3] +";
}

sub TIMES {
  "$_[1] $_[3] *";
}

package main;
use strict;

my $calcparser = CalcActions->new();
print "Write an expression: "; 
my $x = <STDIN>;
my $e = $calcparser->Run(
  0,  # debug mode
  $x  # input
);

unless ($calcparser->YYNberr) {
  print "$e\n";

  my $postparser = PostActions->new();
  my $p = $postparser->Run(0, $x);

  print "$p\n";
}
