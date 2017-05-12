#!/usr/bin/perl
#
# dummy test to save code that checks if a function is 
# overriddable and print the prototype
#
# see: http://perldoc.perl.org/perlsub.html#Overriding-Built-in-Functions
# for more information

use strict;

my $tcount = 0;

foreach (keys %ENV) {
  ++$tcount if	$_ =~ /^MAKELEVEL/ ||
		$_ =~ /^PERL/;
}

unless ($tcount < 2) {	# not make test
  print "1..1\n";
  print "ok 1\n";
} else {
  my $func = $ARGV[0];
  unless ($func) {
    print q|
usage:	$0  function-name

|;
  }
  else {
    my $prototype = prototype "CORE::$func";
    print "$func is ", defined $prototype
	? "overridable with $prototype"
	: "not overridable", "\n";
  }
}
