#!/usr/local/bin/perl -w

use strict;
use Proc::InvokeEditor;

my @result = Proc::InvokeEditor->edit("foo\nbar\nbaz\n");

use Data::Dumper;
print Dumper(@result);

foreach my $line (@result) {
  print "Line: $line\n";
}
