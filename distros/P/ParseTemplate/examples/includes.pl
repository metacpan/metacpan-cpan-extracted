#!/usr/local/bin/perl -w

# Process a document including directives like this:
# 
#  <html><body>%%include("body.htm")%%</html></body>
#              \_____________________/
# 
require 5.004; 
use strict;
use Parse::Template;

use constant TRACE => 1;
my $T = new Parse::Template();
$T->env('include' => sub {
	  shift if ref $_[0];
	  print STDERR "include $_[0]\n" if TRACE;
	  local *FH;
	  open FH, "< $_[0]" or die "unable to open '$_[0]': $!";
	  my $text = join '', <FH>;
	  $T->setPart(INCLUDE => $text);
	  $T->INCLUDE();
	});

if (@ARGV) {
  print $T->include($ARGV[0]);
} else {
  print $T->include('root.htm');
}
